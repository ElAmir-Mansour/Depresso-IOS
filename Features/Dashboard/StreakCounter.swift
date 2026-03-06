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
                // Current Streak - Dynamic visualization
                VStack(spacing: DesignSystem.Spacing.small) {
                    ZStack {
                        Circle()
                            .fill(Color.ds.accent.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        if ThemeManager.shared.currentStyle == .coffee {
                            // The Bean Jar (Coffee Theme)
                            DSIcon(jarAsset, size: 60)
                                .offset(y: -4)
                            
                            Text("\(currentStreak)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(6)
                                .background(Color.ds.accent)
                                .clipShape(Circle())
                                .offset(x: 20, y: 20)
                        } else {
                            // Classic Streak Visualization
                            VStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color.ds.accent.gradient)
                                Text("\(currentStreak)")
                                    .font(.system(.title, design: .rounded).weight(.bold))
                                    .foregroundColor(.ds.accent)
                            }
                        }
                    }
                    
                    Text(ThemeManager.shared.currentStyle == .coffee ? "Beans Collected" : "Days")
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
        .background(Color.ds.cardBackground)
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
    
    private var jarAsset: String {
        if currentStreak == 0 {
            return "custom:jar-empty"
        } else if currentStreak < 7 {
            return "custom:jar-half-full"
        } else {
            return "custom:jar-full"
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
        
        // Normalize dates to start of day and get unique dates sorted descending
        let uniqueDates = Array(Set(assessments.map { calendar.startOfDay(for: $0.date) }))
            .sorted(by: >)
        
        guard let mostRecent = uniqueDates.first else { return 0 }
        
        // Check if the most recent assessment is today or yesterday
        let daysFromToday = calendar.dateComponents([.day], from: mostRecent, to: today).day ?? 0
        
        // Relaxed check: <= 1 allows today (0), yesterday (1), or even future due to TZ shift (-1)
        if daysFromToday > 1 {
            return 0 // Streak broken
        }
        
        var streak = 1
        for i in 1..<uniqueDates.count {
            let prev = uniqueDates[i-1]
            let curr = uniqueDates[i]
            let gap = calendar.dateComponents([.day], from: curr, to: prev).day ?? 0
            
            if gap == 1 {
                streak += 1
            } else {
                break // Gap found
            }
        }
        
        return streak
    }
    
    /// Calculate longest streak from assessment history
    static func calculateLongestStreak(from assessments: [DailyAssessment]) -> Int {
        guard !assessments.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        // Normalize dates to start of day and get unique dates sorted ascending
        let uniqueDates = Array(Set(assessments.map { calendar.startOfDay(for: $0.date) }))
            .sorted(by: <)
        
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<uniqueDates.count {
            let prev = uniqueDates[i-1]
            let curr = uniqueDates[i]
            let gap = calendar.dateComponents([.day], from: prev, to: curr).day ?? 0
            
            if gap == 1 {
                currentStreak += 1
            } else {
                maxStreak = max(maxStreak, currentStreak)
                currentStreak = 1
            }
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
