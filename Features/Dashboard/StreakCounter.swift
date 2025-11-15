// Features/Dashboard/StreakCounter.swift
import SwiftUI

struct StreakCounterView: View {
    let currentStreak: Int
    let longestStreak: Int
    @State private var showConfetti = false
    @State private var previousStreak: Int?
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("Check-in Streak")
                    .font(.ds.headline)
                Spacer()
            }
            
            HStack(spacing: DesignSystem.Spacing.large) {
                // Current Streak
                VStack(spacing: DesignSystem.Spacing.small) {
                    ZStack {
                        Circle()
                            .fill(Color.ds.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 4) {
                            Text("🔥")
                                .font(.system(size: 32))
                            Text("\(currentStreak)")
                                .font(.system(.title, design: .rounded).weight(.bold))
                                .foregroundColor(.ds.accent)
                        }
                    }
                    
                    Text("Current")
                        .font(.ds.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Longest Streak
                VStack(spacing: DesignSystem.Spacing.small) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        VStack(spacing: 4) {
                            Text("🏆")
                                .font(.system(size: 32))
                            Text("\(longestStreak)")
                                .font(.system(.title, design: .rounded).weight(.bold))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("Best")
                        .font(.ds.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Motivational message
            if currentStreak > 0 {
                Text(motivationalMessage)
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, DesignSystem.Spacing.small)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            if showConfetti {
                ConfettiView()
                    .transition(.opacity)
            }
        }
        .onChange(of: currentStreak) { oldValue, newValue in
            // Celebrate milestone streaks!
            if let previous = previousStreak, newValue > previous {
                if isMilestone(newValue) {
                    celebrateMilestone()
                }
            }
            previousStreak = newValue
        }
        .onAppear {
            previousStreak = currentStreak
        }
    }
    
    private var motivationalMessage: String {
        switch currentStreak {
        case 0:
            return "Start your streak today! 🌟"
        case 1:
            return "Great start! Keep it going! 💪"
        case 2...6:
            return "You're building a habit! 🎯"
        case 7:
            return "One week strong! Amazing! 🎉"
        case 8...13:
            return "You're on fire! Keep it up! 🔥"
        case 14:
            return "Two weeks! You're unstoppable! ⚡️"
        case 15...29:
            return "Incredible dedication! 🌟"
        case 30:
            return "30 days! You're a champion! 🏆"
        default:
            return "Legendary streak! Keep going! 👑"
        }
    }
    
    // MARK: - Helper Methods
    
    private func isMilestone(_ streak: Int) -> Bool {
        // Milestones: 3, 7, 14, 30, 60, 90, 100, 365
        [3, 7, 14, 30, 60, 90, 100, 365].contains(streak)
    }
    
    private func celebrateMilestone() {
        DSHaptics.success()
        withAnimation {
            showConfetti = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
                showConfetti = false
            }
        }
    }
}

// Helper to calculate streaks
struct StreakCalculator {
    /// Calculate current streak from assessment history
    static func calculateCurrentStreak(from assessments: [DailyAssessment]) -> Int {
        guard !assessments.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Sort by date descending (most recent first)
        let sortedAssessments = assessments.sorted { $0.date > $1.date }
        
        // Check if there's an assessment today or yesterday
        guard let mostRecent = sortedAssessments.first else { return 0 }
        let mostRecentDay = calendar.startOfDay(for: mostRecent.date)
        
        // If most recent is more than 1 day ago, streak is broken
        let daysSinceRecent = calendar.dateComponents([.day], from: mostRecentDay, to: today).day ?? 0
        if daysSinceRecent > 1 {
            return 0
        }
        
        // Count consecutive days
        var streak = 0
        var expectedDate = today
        
        for assessment in sortedAssessments {
            let assessmentDay = calendar.startOfDay(for: assessment.date)
            
            if assessmentDay == expectedDate {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if assessmentDay < expectedDate {
                // Gap in streak
                break
            }
            // Skip duplicates on same day
        }
        
        return streak
    }
    
    /// Calculate longest streak from assessment history
    static func calculateLongestStreak(from assessments: [DailyAssessment]) -> Int {
        guard !assessments.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let sortedAssessments = assessments.sorted { $0.date < $1.date }
        
        var maxStreak = 0
        var currentStreak = 0
        var lastDate: Date?
        
        for assessment in sortedAssessments {
            let assessmentDay = calendar.startOfDay(for: assessment.date)
            
            if let last = lastDate {
                let lastDay = calendar.startOfDay(for: last)
                let daysBetween = calendar.dateComponents([.day], from: lastDay, to: assessmentDay).day ?? 0
                
                if daysBetween == 1 {
                    // Consecutive day
                    currentStreak += 1
                } else if daysBetween > 1 {
                    // Gap found, reset
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
                // If same day, skip (don't reset streak)
            } else {
                currentStreak = 1
            }
            
            lastDate = assessmentDay
        }
        
        return max(maxStreak, currentStreak)
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        StreakCounterView(currentStreak: 7, longestStreak: 14)
        StreakCounterView(currentStreak: 0, longestStreak: 5)
        StreakCounterView(currentStreak: 30, longestStreak: 30)
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
