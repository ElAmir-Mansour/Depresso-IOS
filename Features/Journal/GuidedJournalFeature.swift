import SwiftUI
import ComposableArchitecture

@Reducer
struct GuidedJournalFeature {
    @ObservableState
    struct State: Equatable {
        var template: CBTTemplate
        var answers: [String: String] = [:]
        var isSubmitting = false
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case submitButtonTapped
        case submissionCompleted(Result<Void, Error>)
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
        title: "Gratitude List",
        description: "Focus on the positive aspects of your day.",
        steps: [
            GuidedStep(id: "item1", question: "What is one good thing that happened today?", placeholder: "Something small or large..."),
            GuidedStep(id: "item2", question: "Who are you grateful for today?", placeholder: "A friend, family member, or even a stranger..."),
            GuidedStep(id: "item3", question: "What is something you accomplished?", placeholder: "I finished my task, I took a walk...")
        ]
    )
    
    static let thoughtRecordTemplate = CBTTemplate(
        id: "thought_record",
        title: "Thought Record",
        description: "Challenge negative thoughts and reframe them.",
        steps: [
            GuidedStep(id: "situation", question: "What was the situation?", placeholder: "Where were you? What was happening?"),
            GuidedStep(id: "thought", question: "What was the automatic thought?", placeholder: "What did you tell yourself?"),
            GuidedStep(id: "evidence", question: "What is the evidence for/against this thought?", placeholder: "Is there another way to look at it?")
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
                return .none
                
            case .submissionCompleted(.failure):
                state.isSubmitting = false
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}

struct GuidedJournalView: View {
    @Bindable var store: StoreOf<GuidedJournalFeature>
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(store.template.title)
                    .font(.ds.title)
                
                Text(store.template.description)
                    .font(.ds.body)
                    .foregroundStyle(.secondary)
                
                ForEach(store.template.steps) { step in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(step.question)
                            .font(.ds.headline)
                        
                        TextEditor(text: Binding(
                            get: { store.answers[step.id] ?? "" },
                            set: { store.answers[step.id] = $0 }
                        ))
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color(uiColor: .secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
                
                Button {
                    store.send(.submitButtonTapped)
                } label: {
                    if store.isSubmitting {
                        ProgressView()
                    } else {
                        Text("Save Entry")
                            .font(.ds.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.ds.accent)
                            .cornerRadius(16)
                    }
                }
                .disabled(store.isSubmitting)
                .padding(.top, 20)
            }
            .padding()
        }
        .background(Color.ds.backgroundPrimary)
    }
}
