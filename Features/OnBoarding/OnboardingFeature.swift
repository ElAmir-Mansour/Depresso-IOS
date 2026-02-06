// In Features/Onboarding/OnboardingFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct OnboardingFeature {
    @ObservableState
    struct State: Equatable {
        var questions: [PHQ8.Question] = PHQ8.allQuestions
        var currentQuestionIndex: Int = 0
        var isCompleted: Bool = false
        var analysis: String?
        var isLoadingAnalysis: Bool = false
        var errorMessage: String?
        
        // ✅ ADDED: State to hold the final score and its interpretation
        var finalScore: Int = 0
        var severity: String = ""
        
        var progress: Double {
            return Double(currentQuestionIndex) / Double(questions.count)
        }
        
        var isNextButtonEnabled: Bool {
            questions[currentQuestionIndex].answer != nil
        }
    }
    
    enum Action {
        case answerQuestion(index: Int, answer: PHQ8.Answer)
        case nextButtonTapped
        case backButtonTapped
        case getAnalysisButtonTapped
        case analysisResponse(Result<String, Error>)
        case delegate(Delegate)
        case saveAssessmentToBackend // NEW
        
        enum Delegate {
            case onboardingCompleted
        }
    }
    
    @Dependency(\.backendAIClient) var backendAIClient
    
    var body: some Reducer<State, Action> {
        Reduce {
            state, action in
            switch action {
            case let .answerQuestion(index, answer):
                state.questions[index].answer = answer
                return .none
                
            case .nextButtonTapped:
                if state.currentQuestionIndex < state.questions.count - 1 {
                    state.currentQuestionIndex += 1
                } else {
                    state.isCompleted = true
                }
                return .none
                
            case .backButtonTapped:
                if state.currentQuestionIndex > 0 {
                    state.currentQuestionIndex -= 1
                }
                return .none
                
            case .getAnalysisButtonTapped:
                state.isLoadingAnalysis = true
                state.errorMessage = nil
                
                // ✅ UPDATED: Calculate and store the score and severity
                let score = state.questions.compactMap(\.answer?.rawValue).reduce(0, +)
                let severity = getSeverity(for: score)
                state.finalScore = score
                state.severity = severity
                
                let prompt = createAnalysisPrompt(score: score, severity: severity)
                
                return .merge(
                    // Generate AI analysis with fallback
                    .run {
                        send in
                        do {
                            print("📊 Generating PHQ-8 analysis for score: \(score), severity: \(severity)")
                            let response = try await backendAIClient.generateResponse([], prompt, nil)
                            print("✅ PHQ-8 analysis generated successfully")
                            await send(.analysisResponse(.success(response)))
                        } catch {
                            print("⚠️ Failed to generate AI analysis, using fallback: \(error)")
                            // Use fallback analysis instead of showing error
                            let fallbackAnalysis = createFallbackAnalysis(score: score, severity: severity)
                            await send(.analysisResponse(.success(fallbackAnalysis)))
                        }
                    },
                    // Save to backend
                    .send(.saveAssessmentToBackend) // NEW
                )
                
            case .analysisResponse(.success(let analysis)):
                state.isLoadingAnalysis = false
                state.analysis = analysis
                return .none
                
            case .analysisResponse(.failure(let error)):
                // This case should never be reached now due to fallback, but keep for safety
                state.isLoadingAnalysis = false
                print("⚠️ Analysis response failure (unexpected): \(error)")
                
                // Use fallback analysis
                let fallbackAnalysis = createFallbackAnalysis(score: state.finalScore, severity: state.severity)
                state.analysis = fallbackAnalysis
                state.errorMessage = nil // Clear any error message
                return .none
                
            case .saveAssessmentToBackend:
                let score = state.finalScore
                let answers = state.questions.compactMap(\.answer?.rawValue)
                
                return .run {
                    send in
                    do {
                        // Ensure user is registered first
                        print("🔄 Ensuring user is registered...")
                        try await UserManager.shared.ensureUserRegistered()
                        let userId = try await UserManager.shared.getCurrentUserId()
                        
                        print("✅ User ID obtained: \(userId)")
                        print("📊 Submitting assessment to backend...")
                        print("   Score: \(score)")
                        print("   Answers: \(answers)")
                        print("   Endpoint: http://192.168.1.11:3000/api/v1/assessments")
                        
                        let assessment = try await APIClient.submitAssessment(
                            userId: userId,
                            assessmentType: "PHQ-8",
                            score: score,
                            answers: answers
                        )
                        
                        print("✅ Assessment submitted successfully!")
                        print("   Assessment ID: \(assessment.id)")
                        print("   Created at: \(assessment.createdAt)")
                        
                    } catch let error as APIError {
                        // Handle API-specific errors with better messages
                        let errorMsg = switch error {
                        case .networkError(let msg):
                            "Network error: \(msg). Please check your connection."
                        case .serverError(let code, let msg):
                            "Server error (\(code)): \(msg)"
                        case .decodingError(let msg):
                            "Data parsing error: \(msg)"
                        case .invalidURL:
                            "Invalid server URL configuration"
                        case .noData:
                            "No response from server"
                        }
                        print("❌ Failed to submit assessment:")
                        print("   Error: \(errorMsg)")
                        print("   Original error: \(error)")
                        // Note: We don't send this error to the UI since analysis already succeeded
                    } catch {
                        print("❌ Unexpected error submitting assessment:")
                        print("   \(error.localizedDescription)")
                        print("   \(error)")
                        // Don't block user flow if this fails - analysis is still generated
                    }
                }
            case .delegate:
                return .none
            }
        }
    }
    
    private func getSeverity(for score: Int) -> String {
        switch score {
        case 0...4: return "Minimal"
        case 5...9: return "Mild"
        case 10...14: return "Moderate"
        case 15...19: return "Moderately Severe"
        default: return "Severe"
        }
    }
    
    private func createAnalysisPrompt(score: Int, severity: String) -> String {
        return """
        A user has completed the PHQ-8 questionnaire and scored \(score), which indicates \(severity.lowercased()) depression symptoms.
        Based on this, please provide a brief, supportive, and encouraging analysis written directly to the user.
        
        - Start with a reassuring and empathetic tone.
        - Briefly explain what the score suggests in simple terms.
        - Suggest that the app's features (like the journal and wellness tasks) can be helpful tools.
        - Frame the app as a supportive companion for their mental wellness journey.
        - Keep the analysis to 3-4 short paragraphs.
        - Do NOT provide a medical diagnosis or medical advice. 
        
        IMPORTANT: Your entire response will be shown directly to the user. Do not include any of your own thoughts, XML tags, or any text that is not part of the final, user-facing analysis.
        """
    }
    
    private func createFallbackAnalysis(score: Int, severity: String) -> String {
        switch severity {
        case "Minimal":
            return """
Thank you for completing the PHQ-8 assessment. Your score of \(score) suggests minimal symptoms of depression. This is a positive sign that you're generally managing well.

While your score indicates you're doing okay, remember that mental wellness is an ongoing journey. Using Depresso's daily check-ins and journal features can help you maintain this positive state and build resilience for the future.

We're here to support you every step of the way. Feel free to explore the app's features like mood tracking, community support, and wellness activities to continue nurturing your mental health.
"""
        case "Mild":
            return """
Thank you for taking the time to complete this assessment. Your score of \(score) indicates mild symptoms of depression. It's important to recognize these feelings, and you've taken a positive step by checking in with yourself.

Many people experience mild symptoms from time to time, and there are effective ways to address them. Depresso can help through daily journaling, mood tracking, and connecting with supportive community members who understand what you're going through.

Remember, you're not alone in this journey. The app's features are designed to provide daily support and help you develop healthy coping strategies. Consider using the journal regularly to express your thoughts and track patterns in your mood.
"""
        case "Moderate":
            return """
Thank you for completing this assessment. Your score of \(score) suggests moderate symptoms of depression. Recognizing and acknowledging how you're feeling is an important and brave step forward.

At this level, it's beneficial to actively engage with supportive resources. Depresso offers tools like daily journaling, mood tracking, and a supportive community to help you through this time. Consider using these features regularly to monitor your progress and connect with others.

While this app can be a valuable support tool, we also encourage you to reach out to a mental health professional who can provide personalized guidance. You deserve support, and combining professional help with daily wellness practices can make a meaningful difference in your journey.
"""
        case "Moderately Severe", "Severe":
            return """
Thank you for taking this important step. Your score of \(score) indicates \(severity.lowercased()) symptoms of depression. Please know that these feelings are real, and you deserve support and care.

While Depresso can provide daily support through journaling and community connection, we strongly encourage you to reach out to a mental health professional. They can provide the specialized care and treatment that can help you feel better. You don't have to face this alone.

In the meantime, use Depresso as a daily companion. The journal can help you express your feelings, track your progress, and maintain a routine. The community is here to support you, and remember—reaching out for professional help is a sign of strength, not weakness.
"""
        default:
            return """
Thank you for completing the PHQ-8 assessment. Your responses help us understand how you're feeling and how we can best support you.

Depresso is designed to be your daily companion for mental wellness. Use the journal to express your thoughts, track your mood patterns, and connect with a supportive community who understands your journey.

Remember, taking care of your mental health is an ongoing process, and we're here to support you every step of the way. Explore the app's features and find what works best for you.
"""
        }
    }
}
