// In Features/Dashboard/DailyAssessmentFeature.swift
import Foundation
import ComposableArchitecture
import SwiftData

@Reducer
struct DailyAssessmentFeature {
    @ObservableState
    struct State: Equatable {
        var questions: [PHQ8.Question] = PHQ8.allQuestions
        var currentQuestionIndex: Int = 0
        var isCompleted: Bool = false
        
        var progress: Double {
            Double(currentQuestionIndex + 1) / Double(questions.count)
        }
        
        var isNextButtonEnabled: Bool {
            questions[currentQuestionIndex].answer != nil
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case answerQuestion(index: Int, answer: PHQ8.Answer)
        case nextButtonTapped
        case backButtonTapped
        case saveAssessment
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate: Equatable {
            case assessmentCompleted(DailyAssessment)
            case cancel
        }
    }

    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .answerQuestion(let index, let answer):
                state.questions[index].answer = answer
                return .none

            case .nextButtonTapped:
                if state.currentQuestionIndex < state.questions.count - 1 {
                    state.currentQuestionIndex += 1
                } else {
                    state.isCompleted = true
                    return .send(.saveAssessment)
                }
                return .none

            case .backButtonTapped:
                if state.currentQuestionIndex > 0 {
                    state.currentQuestionIndex -= 1
                }
                return .none

            case .saveAssessment:
                let score = state.questions.compactMap(\.answer?.rawValue).reduce(0, +)
                
                return .run { send in
                    let userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? "guest"
                    let assessment = DailyAssessment(userId: userId, date: now, score: score)
                    
                    DSHaptics.success()
                    await send(.delegate(.assessmentCompleted(assessment)))
                    await self.dismiss()
                }

            case .delegate(.cancel):
                 return .run { _ in await self.dismiss() }

            case .binding, .delegate:
                return .none
            }
        }
    }
}
