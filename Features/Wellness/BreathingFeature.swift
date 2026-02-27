import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct BreathingFeature {
    @ObservableState
    struct State: Equatable {
        var isRunning = false
        var phase: BreathingPhase = .inhale
        var secondsRemaining = 4
        var cyclesCompleted = 0
        var totalCyclesGoal = 5
        var startDate: Date?
        var isCompleted = false // NEW
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case startButtonTapped
        case stopButtonTapped
        case timerTick
        case dismissButtonTapped // NEW
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case finished
        }
    }
    
    @Dependency(\.healthClient) var healthClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.continuousClock) var clock // NEW
    
    enum BreathingPhase: String {
        case inhale = "Inhale"
        case holdIn = "Hold In"
        case exhale = "Exhale"
        case holdOut = "Hold Out"
        
        var duration: Int {
            switch self {
            case .inhale, .holdIn, .exhale, .holdOut: return 4
            }
        }
        
        var next: BreathingPhase {
            switch self {
            case .inhale: return .holdIn
            case .holdIn: return .exhale
            case .exhale: return .holdOut
            case .holdOut: return .inhale
            }
        }
    }
    
    private enum CancelID { case timer }
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .startButtonTapped:
                state.isRunning = true
                state.isCompleted = false
                state.cyclesCompleted = 0
                state.phase = .inhale
                state.secondsRemaining = state.phase.duration
                state.startDate = .now
                DSHaptics.buttonPress()
                return .run { send in
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .stopButtonTapped:
                state.isRunning = false
                return .cancel(id: CancelID.timer)
                
            case .dismissButtonTapped:
                return .run { _ in await self.dismiss() }
                
            case .timerTick:
                state.secondsRemaining -= 1
                if state.secondsRemaining <= 0 {
                    let prevPhase = state.phase
                    state.phase = state.phase.next
                    state.secondsRemaining = state.phase.duration
                    
                    // Add haptic feedback for phase change
                    DSHaptics.selection()
                    
                    if prevPhase == .holdOut {
                        state.cyclesCompleted += 1
                        if state.cyclesCompleted >= state.totalCyclesGoal {
                            state.isRunning = false
                            state.isCompleted = true
                            
                            // Save to HealthKit
                            let start = state.startDate ?? .now
                            return .run { [healthClient] _ in
                                try? await healthClient.saveMindfulSession(start, .now)
                            }
                            .merge(with: .cancel(id: CancelID.timer))
                        }
                    }
                }
                return .none
                
            case .delegate, .binding:
                return .none
            }
        }
    }
}

struct BreathingView: View {
    let store: StoreOf<BreathingFeature>
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.ds.backgroundPrimary.ignoresSafeArea()
            
            if store.isCompleted {
                completionView
            } else {
                exerciseView
            }
            
            // Top Controls
            VStack {
                HStack {
                    Button {
                        store.send(.dismissButtonTapped)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.secondary.opacity(0.5))
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }
    
    private var exerciseView: some View {
        VStack(spacing: 40) {
            Text("Box Breathing")
                .font(.ds.title)
                .padding(.top, 40)
            
            Text("Focus on your breath to calm your mind.")
                .font(.ds.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            // Animated Circle
            ZStack {
                Circle()
                    .stroke(Color.ds.accent.opacity(0.1), lineWidth: 20)
                    .frame(width: 250, height: 250)
                
                Circle()
                    .fill(Color.ds.accent.gradient)
                    .frame(width: circleSize, height: circleSize)
                    .animation(.easeInOut(duration: 4.0), value: store.phase)
                    .shadow(color: Color.ds.accent.opacity(0.3), radius: 20)
                
                VStack {
                    Text(store.phase.rawValue)
                        .font(.ds.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    if store.isRunning {
                        Text("\(store.secondsRemaining)")
                            .font(.ds.displayMedium)
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(height: 300)
            
            // Progress Bar
            VStack(spacing: 8) {
                Text("Cycle \(store.cyclesCompleted) of \(store.totalCyclesGoal)")
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
                
                ProgressView(value: Double(store.cyclesCompleted), total: Double(store.totalCyclesGoal))
                    .tint(Color.ds.accent)
                    .frame(width: 200)
            }
            
            Spacer()
            
            if !store.isRunning {
                Button {
                    store.send(.startButtonTapped)
                } label: {
                    Text("Start Exercise")
                        .font(.ds.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.ds.accent)
                        .cornerRadius(16)
                        .shadow(color: Color.ds.accent.opacity(0.3), radius: 10, y: 5)
                }
                .padding(.horizontal, 30)
            } else {
                Button {
                    store.send(.stopButtonTapped)
                } label: {
                    Text("Stop")
                        .font(.ds.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                }
                .padding(.horizontal, 30)
            }
            
            Spacer()
        }
    }
    
    private var completionView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.ds.accent.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.ds.accent)
            }
            
            VStack(spacing: 16) {
                Text("Excellent Work!")
                    .font(.ds.title)
                    .fontWeight(.bold)
                
                Text("You've completed \(store.totalCyclesGoal) cycles of box breathing. Take a moment to notice how you feel.")
                    .font(.ds.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.ds.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.ds.accent)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .onAppear {
            DSHaptics.success()
        }
    }
    
    private var circleSize: CGFloat {
        guard store.isRunning else { return 100 }
        switch store.phase {
        case .inhale: return 250
        case .holdIn: return 250
        case .exhale: return 100
        case .holdOut: return 100
        }
    }
}

#Preview {
    BreathingView(
        store: Store(initialState: BreathingFeature.State()) {
            BreathingFeature()
        }
    )
}
