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
        var showResults: Bool = false
        var finalScore: Int = 0
        
        var progress: Double {
            Double(currentQuestionIndex + 1) / Double(questions.count)
        }
        
        var isNextButtonEnabled: Bool {
            questions[currentQuestionIndex].answer != nil
        }
        
        var severity: PHQ8Severity {
            PHQ8Severity(score: finalScore)
        }
    }

    enum PHQ8Severity: String {
        case minimal = "Minimal"
        case mild = "Mild"
        case moderate = "Moderate"
        case moderatelySevere = "Moderately Severe"
        case severe = "Severe"
        
        init(score: Int) {
            switch score {
            case 0...4: self = .minimal
            case 5...9: self = .mild
            case 10...14: self = .moderate
            case 15...19: self = .moderatelySevere
            default: self = .severe
            }
        }
        
        var color: String {
            switch self {
            case .minimal: return "#4CAF50"
            case .mild: return "#8BC34A"
            case .moderate: return "#FFC107"
            case .moderatelySevere: return "#FF9800"
            case .severe: return "#F44336"
            }
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case answerQuestion(index: Int, answer: PHQ8.Answer)
        case nextButtonTapped
        case backButtonTapped
        case saveAssessment
        case finishButtonTapped
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
                state.finalScore = score
                state.isCompleted = true
                state.showResults = true
                
                return .run { send in
                    let userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? "guest"
                    let assessment = DailyAssessment(userId: userId, date: now, score: score)
                    
                    DSHaptics.success()
                    await send(.delegate(.assessmentCompleted(assessment)))
                }
                
            case .finishButtonTapped:
                return .run { _ in await self.dismiss() }

            case .delegate(.cancel):
                 return .run { _ in await self.dismiss() }

            case .binding, .delegate:
                return .none
            }
        }
    }
}
