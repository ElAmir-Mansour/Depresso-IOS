// Features/Dashboard/DailyAssessmentView.swift
import SwiftUI
import ComposableArchitecture

struct DailyAssessmentView: View {
    @Bindable var store: StoreOf<DailyAssessmentFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ds.backgroundPrimary.ignoresSafeArea()
                
                if store.showResults {
                    resultsView
                } else {
                    assessmentContent
                }
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !store.showResults {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { store.send(.delegate(.cancel)) }
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var assessmentContent: some View {
        VStack(spacing: 0) {
            // Progress Bar
            ProgressView(value: store.progress)
                .padding(.horizontal)
                .padding(.top, 16)
                .tint(Color.ds.accent)
            
            ScrollView {
                VStack(spacing: 32) {
                    let currentQuestion = store.questions[store.currentQuestionIndex]
                    
                    VStack(spacing: 12) {
                        Text("Step \(store.currentQuestionIndex + 1) of \(store.questions.count)")
                            .font(.ds.caption.weight(.bold))
                            .foregroundStyle(Color.ds.accent)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.ds.accent.opacity(0.1))
                            .clipShape(Capsule())
                        
                        Text("Over the last 24 hours, how often have you been bothered by:")
                            .font(.ds.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Text(currentQuestion.text)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 40)
                    
                    VStack(spacing: 12) {
                        ForEach(PHQ8.Answer.allCases, id: \.self) { answer in
                            Button {
                                DSHaptics.selection()
                                store.send(.answerQuestion(index: store.currentQuestionIndex, answer: answer))
                                // Auto-advance after small delay for better UX
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    store.send(.nextButtonTapped)
                                }
                            } label: {
                                HStack {
                                    Text(answer.description)
                                        .font(.ds.body.weight(.medium))
                                    Spacer()
                                    if store.questions[store.currentQuestionIndex].answer == answer {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.white)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    store.questions[store.currentQuestionIndex].answer == answer ?
                                    Color.ds.accent : Color(UIColor.secondarySystemGroupedBackground)
                                )
                                .foregroundStyle(
                                    store.questions[store.currentQuestionIndex].answer == answer ?
                                    .white : .primary
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // Bottom Controls
            HStack {
                if store.currentQuestionIndex > 0 {
                    Button {
                        DSHaptics.light()
                        store.send(.backButtonTapped)
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
                
                if !store.isNextButtonEnabled {
                    Text("Select an answer to continue")
                        .font(.ds.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(24)
            .background(Color.ds.backgroundPrimary)
        }
    }
    
    private var resultsView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            if ThemeManager.shared.currentStyle == .coffee {
                // Coffee Theme Results
                ZStack {
                    Circle()
                        .fill(severityColor.opacity(0.1))
                        .frame(width: 220, height: 220)
                        .blur(radius: 20)
                    
                    DSIcon(severityIllustration, size: 160)
                        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                    
                    Text("\(store.finalScore)")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(severityColor)
                        .clipShape(Circle())
                        .offset(x: 60, y: 60)
                }
            } else {
                // Classic Theme Results
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.1), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(store.finalScore) / 24.0)
                        .stroke(
                            severityColor.gradient,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(store.finalScore)")
                            .font(.system(size: 60, weight: .heavy, design: .rounded))
                        Text("Total Score")
                            .font(.ds.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            VStack(spacing: 12) {
                Text(store.severity.rawValue)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(severityColor)
                
                Text(severityDescription(store.severity))
                    .font(.ds.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button {
                DSHaptics.buttonPress()
                store.send(.finishButtonTapped)
            } label: {
                Text("Back to Dashboard")
                    .font(.ds.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.ds.accent)
                    .cornerRadius(16)
                    .shadow(color: Color.ds.accent.opacity(0.3), radius: 10, y: 5)
            }
            .padding(24)
        }
    }
    
    private var severityColor: Color {
        switch store.severity {
        case .minimal, .mild: return Color.ds.success
        case .moderate: return Color.ds.warning
        case .moderatelySevere, .severe: return Color.ds.error
        }
    }
    
    private var severityIllustration: String {
        switch store.severity {
        case .minimal, .mild: 
            return DSIcons.successState
        case .moderate:
            return DSIcons.successState
        case .moderatelySevere, .severe:
            return DSIcons.errorState
        }
    }
    
    private func severityDescription(_ severity: DailyAssessmentFeature.PHQ8Severity) -> String {
        switch severity {
        case .minimal:
            return "Your responses suggest minimal depressive symptoms. Keep up your wellness routine!"
        case .mild:
            return "You're experiencing some mild symptoms. Consider using the AI Companion or Journaling tools to explore your thoughts."
        case .moderate:
            return "Your symptoms are in the moderate range. It might be helpful to reach out to a friend or professional for support."
        case .moderatelySevere:
            return "You're going through a tough time. Please consider speaking with a mental health professional."
        case .severe:
            return "Your symptoms suggest severe distress. We strongly recommend reaching out to a professional or using our Support tab hotlines."
        }
    }
}

#Preview {
    DailyAssessmentView(
        store: Store(initialState: DailyAssessmentFeature.State()) {
            DailyAssessmentFeature()
        }
    )
}
