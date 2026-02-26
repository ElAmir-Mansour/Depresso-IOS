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
        var startDate: Date? // NEW
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case startButtonTapped
        case stopButtonTapped
        case timerTick
    }
    
    @Dependency(\.healthClient) var healthClient // NEW
    
    enum BreathingPhase: String {
        case inhale = "Inhale"
        case holdIn = "Hold"
        case exhale = "Exhale"
        case holdOut = "Hold"
        
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
                state.phase = .inhale
                state.secondsRemaining = state.phase.duration
                state.startDate = .now // Track start
                return .run { send in
                    while true {
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)
                
            case .stopButtonTapped:
                state.isRunning = false
                return .cancel(id: CancelID.timer)
                
            case .timerTick:
                state.secondsRemaining -= 1
                if state.secondsRemaining <= 0 {
                    let prevPhase = state.phase
                    state.phase = state.phase.next
                    state.secondsRemaining = state.phase.duration
                    
                    if prevPhase == .holdOut {
                        state.cyclesCompleted += 1
                        if state.cyclesCompleted >= state.totalCyclesGoal {
                            state.isRunning = false
                            
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
                
            case .binding:
                return .none
            }
        }
    }
}

struct BreathingView: View {
    let store: StoreOf<BreathingFeature>
    
    var body: some View {
        VStack(spacing: 40) {
            Text("Box Breathing")
                .font(.ds.title1)
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
                    .stroke(Color.ds.accent.opacity(0.2), lineWidth: 20)
                    .frame(width: 250, height: 200)
                
                Circle()
                    .fill(Color.ds.accent.gradient)
                    .frame(width: circleSize, height: circleSize)
                    .animation(.easeInOut(duration: 4.0), value: store.phase)
                
                VStack {
                    Text(store.phase.rawValue)
                        .font(.ds.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(store.secondsRemaining)")
                        .font(.ds.largeTitle)
                        .foregroundColor(.white)
                }
            }
            .frame(height: 300)
            
            Text("Cycles: \(store.cyclesCompleted) / \(store.totalCyclesGoal)")
                .font(.ds.headline)
            
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
        .padding()
        .background(Color.ds.backgroundPrimary)
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
