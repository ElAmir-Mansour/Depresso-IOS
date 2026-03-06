import SwiftUI
import ComposableArchitecture

@Reducer
struct GuidedJournalFeature {
    @ObservableState
    struct State: Equatable {
        var template: CBTTemplate
        var answers: [String: String] = [:]
        var isSubmitting = false
        var showSuccess = false
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submitButtonTapped
        case submissionCompleted(Result<Void, Error>)
        case dismissTriggered
    }
    
    struct CBTTemplate: Equatable, Identifiable {
        let id: String
        let title: String
        let description: String
        let steps: [GuidedStep]
    }
    
    struct GuidedStep: Equatable, Identifiable {
        let id: String
        let question: String
        let placeholder: String
    }
    
    static let gratitudeTemplate = CBTTemplate(
        id: "gratitude",
        title: "Gratitude & Joy",
        description: "Focus on the positive aspects of your day to build resilience.",
        steps: [
            GuidedStep(id: "item1", question: "What is one good thing that happened today?", placeholder: "Take a deep breath and reflect on a positive moment..."),
            GuidedStep(id: "item2", question: "How did that good thing make you feel?", placeholder: "Did you feel peace, joy, warmth? Where in your body did you feel it?"),
            GuidedStep(id: "item3", question: "Who are you grateful for today, and why?", placeholder: "A friend, family member, or even a stranger..."),
            GuidedStep(id: "item4", question: "What is something small you accomplished?", placeholder: "Even getting out of bed or taking a shower is an accomplishment...")
        ]
    )
    
    static let thoughtRecordTemplate = CBTTemplate(
        id: "thought_record",
        title: "Thought Record",
        description: "Challenge automatic negative thoughts and reframe them.",
        steps: [
            GuidedStep(id: "situation", question: "What was the situation?", placeholder: "Where were you? What was happening?"),
            GuidedStep(id: "thought", question: "What was the automatic negative thought?", placeholder: "What did your inner critic tell you?"),
            GuidedStep(id: "emotion", question: "How did you feel in your body?", placeholder: "Did your chest tighten? Fast heartbeat? Name the emotion."),
            GuidedStep(id: "evidence", question: "What is the evidence against this thought?", placeholder: "Is there another, more gentle way to look at it?"),
            GuidedStep(id: "reframed", question: "What is a more balanced, kind thought?", placeholder: "Speak to yourself like you would a good friend...")
        ]
    )
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .submitButtonTapped:
                state.isSubmitting = true
                let combinedContent = state.template.steps.map { step in
                    let answer = state.answers[step.id] ?? ""
                    return "**\(step.question)**\n\(answer)"
                }.joined(separator: "\n\n")
                
                return .run { [template = state.template] send in
                    do {
                        let userId = try await UserManager.shared.getCurrentUserId()
                        _ = try await APIClient.createJournalEntry(
                            userId: userId,
                            title: "Guided: \(template.title)",
                            content: combinedContent
                        )
                        await send(.submissionCompleted(.success(())))
                    } catch {
                        await send(.submissionCompleted(.failure(error)))
                    }
                }
                
            case .submissionCompleted(.success):
                state.isSubmitting = false
                state.showSuccess = true
                DSHaptics.success()
                return .run { send in
                    try await Task.sleep(nanoseconds: 2_000_000_000)
                    await send(.dismissTriggered)
                }
                
            case .submissionCompleted(.failure):
                state.isSubmitting = false
                // Handle error alert in a real app
                return .none
                
            case .dismissTriggered:
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}

struct GuidedJournalView: View {
    @Bindable var store: StoreOf<GuidedJournalFeature>
    @Environment(\.dismiss) var dismiss
    @State private var currentStepIndex = 0
    @FocusState private var focusedStepId: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.ds.backgroundPrimary.ignoresSafeArea()
                
                if store.showSuccess {
                    successState
                } else if store.isSubmitting {
                    loadingState
                } else {
                    mainContent
                }
            }
            .navigationTitle(store.template.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !store.showSuccess && !store.isSubmitting {
                        Button("Cancel") { dismiss() }
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: store.showSuccess) {
                if store.showSuccess {
                    // Start confetti or haptics if needed
                }
            }
            .onAppear {
                // Focus the first step when the view appears
                if let firstStep = store.template.steps.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        focusedStepId = firstStep.id
                    }
                }
            }
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: Double(currentStepIndex + 1), total: Double(store.template.steps.count))
                .tint(Color.ds.accent)
                .padding(.horizontal)
                .padding(.top, 16)
            
            // Paged Content
            TabView(selection: $currentStepIndex) {
                ForEach(Array(store.template.steps.enumerated()), id: \.element.id) { index, step in
                    stepView(for: step, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStepIndex)
            
            // Bottom Controls
            bottomControls
                .padding()
                .background(Color.ds.backgroundPrimary)
                .shadow(color: .black.opacity(0.05), radius: 10, y: -5)
        }
    }
    
    private func stepView(for step: GuidedJournalFeature.GuidedStep, index: Int) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Step \(index + 1) of \(store.template.steps.count)")
                    .font(.ds.caption.weight(.bold))
                    .foregroundStyle(Color.ds.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.ds.accent.opacity(0.1))
                    .clipShape(Capsule())
                
                Text(step.question)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds.textPrimary)
                    .lineSpacing(4)
                
                TextField(step.placeholder, text: Binding(
                    get: { store.answers[step.id] ?? "" },
                    set: { store.answers[step.id] = $0 }
                ), axis: .vertical)
                .font(.ds.body)
                .lineLimit(8...)
                .focused($focusedStepId, equals: step.id)
                .padding()
                .background(Color(uiColor: .secondarySystemBackground))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ds.border, lineWidth: 1)
                )
            }
            .padding(24)
        }
    }
    
    private var bottomControls: some View {
        HStack(spacing: 16) {
            if currentStepIndex > 0 {
                Button {
                    DSHaptics.light()
                    withAnimation { currentStepIndex -= 1 }
                    focusedStepId = store.template.steps[currentStepIndex].id
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 56, height: 56)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(Circle())
                }
            }
            
            Spacer()
            
            let isLastStep = currentStepIndex == store.template.steps.count - 1
            let currentStepId = store.template.steps[currentStepIndex].id
            let hasAnswer = !(store.answers[currentStepId]?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
            
            Button {
                DSHaptics.buttonPress()
                if isLastStep {
                    focusedStepId = nil
                    store.send(.submitButtonTapped)
                } else {
                    withAnimation { currentStepIndex += 1 }
                    // Automatically focus the next step
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        focusedStepId = store.template.steps[currentStepIndex].id
                    }
                }
            } label: {
                Text(isLastStep ? "Complete" : "Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(hasAnswer ? Color.ds.accent : Color.gray.opacity(0.5))
                    .cornerRadius(16)
                    .shadow(color: hasAnswer ? Color.ds.accent.opacity(0.4) : .clear, radius: 8, y: 4)
            }
            .disabled(!hasAnswer)
        }
    }
    
    private var loadingState: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.ds.accent)
            
            Text("Saving your reflection...")
                .font(.ds.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var successState: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.ds.accent.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.ds.accent)
            }
            .transition(.scale.combined(with: .opacity))
            
            VStack(spacing: 8) {
                Text("Reflection Saved")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                
                Text("You took a meaningful step for your mind today. Be proud of yourself.")
                    .font(.ds.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}
