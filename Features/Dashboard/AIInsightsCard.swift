// Features/Dashboard/AIInsightsCard.swift
import SwiftUI

struct AIInsightsCard: View {
    let insights: [HealthInsight]
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Text("AI Insights")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                Spacer()
                
                if !insights.isEmpty {
                    Text("\(insights.count)")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.purple))
                }
            }
            
            if insights.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary)
                    
                    Text("Complete your daily activities to get personalized AI-powered insights!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, DesignSystem.Spacing.medium)
            } else {
                VStack(spacing: DesignSystem.Spacing.small) {
                    ForEach(insights) { insight in
                        InsightRow(insight: insight)
                        if insight.id != insights.last?.id {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.08),
                                Color.blue.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: .purple.opacity(0.1), radius: 10, x: 0, y: 4)
    }
}

struct InsightRow: View {
    let insight: HealthInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(insight.type.color.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: insight.type.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(insight.type.color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            // Trend indicator
            if let trend = insight.trend {
                TrendIndicator(trend: trend)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TrendIndicator: View {
    let trend: InsightTrend
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: trend.icon)
                .font(.system(size: 12, weight: .bold))
            Text(trend.percentage)
                .font(.system(.caption2, design: .rounded).weight(.bold))
        }
        .foregroundStyle(trend.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(trend.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Models

struct HealthInsight: Identifiable, Equatable {
    let id = UUID()
    let type: InsightType
    let title: String
    let message: String
    let trend: InsightTrend?
    
    enum InsightType {
        case activity
        case mood
        case heart
        case energy
        case celebration
        case warning
        
        var icon: String {
            switch self {
            case .activity: return "figure.walk"
            case .mood: return "face.smiling"
            case .heart: return "heart.fill"
            case .energy: return "bolt.fill"
            case .celebration: return "star.fill"
            case .warning: return "exclamationmark.triangle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .activity: return .blue
            case .mood: return .purple
            case .heart: return .pink
            case .energy: return .orange
            case .celebration: return .yellow
            case .warning: return .red
            }
        }
    }
}

struct InsightTrend: Equatable {
    let percentage: String
    let isPositive: Bool
    
    var icon: String {
        isPositive ? "arrow.up.right" : "arrow.down.right"
    }
    
    var color: Color {
        isPositive ? .green : .red
    }
}

// MARK: - Insight Generator

struct InsightGenerator {
    /// Generate insights based on health metrics and history
    static func generateInsights(
        currentMetrics: [HealthMetric],
        weeklySteps: [StepData],
        weeklyEnergy: [EnergyData],
        assessmentHistory: [DailyAssessment],
        currentStreak: Int
    ) -> [HealthInsight] {
        var insights: [HealthInsight] = []
        
        // Activity Insights
        if let activityInsight = generateActivityInsight(weeklySteps: weeklySteps) {
            insights.append(activityInsight)
        }
        
        // Energy Insights
        if let energyInsight = generateEnergyInsight(weeklyEnergy: weeklyEnergy) {
            insights.append(energyInsight)
        }
        
        // Mood Insights
        if let moodInsight = generateMoodInsight(assessmentHistory: assessmentHistory) {
            insights.append(moodInsight)
        }
        
        // Streak Insights
        if let streakInsight = generateStreakInsight(currentStreak: currentStreak) {
            insights.append(streakInsight)
        }
        
        // Heart Rate Insights
        if let heartInsight = generateHeartRateInsight(currentMetrics: currentMetrics) {
            insights.append(heartInsight)
        }
        
        return Array(insights.prefix(3)) // Show top 3 insights
    }
    
    private static func generateActivityInsight(weeklySteps: [StepData]) -> HealthInsight? {
        guard weeklySteps.count >= 2 else { return nil }
        
        let recent = weeklySteps.suffix(3)
        let older = weeklySteps.prefix(weeklySteps.count - 3)
        
        guard !older.isEmpty, !recent.isEmpty else { return nil }
        
        let recentAvg = recent.map(\.count).reduce(0, +) / Double(recent.count)
        let olderAvg = older.map(\.count).reduce(0, +) / Double(older.count)
        
        let change = ((recentAvg - olderAvg) / olderAvg) * 100
        
        if change > 10 {
            return HealthInsight(
                type: .activity,
                title: "Activity Boost!",
                message: "Your step count is up! Keep moving to maintain this momentum.",
                trend: InsightTrend(percentage: "+\(Int(change))%", isPositive: true)
            )
        } else if change < -10 {
            return HealthInsight(
                type: .activity,
                title: "Activity Dip",
                message: "Your activity has decreased. Try a short walk today!",
                trend: InsightTrend(percentage: "\(Int(change))%", isPositive: false)
            )
        }
        
        return nil
    }
    
    private static func generateEnergyInsight(weeklyEnergy: [EnergyData]) -> HealthInsight? {
        guard weeklyEnergy.count >= 2 else { return nil }
        
        let recent = weeklyEnergy.suffix(3)
        let recentAvg = recent.map(\.value).reduce(0, +) / Double(recent.count)
        
        if recentAvg > 400 {
            return HealthInsight(
                type: .energy,
                title: "High Energy Week!",
                message: "You're crushing your calorie goals! Great work.",
                trend: nil
            )
        } else if recentAvg < 200 {
            return HealthInsight(
                type: .energy,
                title: "Energy Opportunity",
                message: "Try adding some light exercise to boost your active energy.",
                trend: nil
            )
        }
        
        return nil
    }
    
    private static func generateMoodInsight(assessmentHistory: [DailyAssessment]) -> HealthInsight? {
        guard assessmentHistory.count >= 3 else { return nil }
        
        let recent = assessmentHistory.suffix(3)
        let recentAvg = recent.map(\.score).reduce(0, +) / recent.count
        
        if assessmentHistory.count >= 6 {
            let older = assessmentHistory.prefix(assessmentHistory.count - 3).suffix(3)
            let olderAvg = older.map(\.score).reduce(0, +) / older.count
            
            let improvement = olderAvg - recentAvg // Lower score is better for PHQ-8
            
            if improvement > 3 {
                return HealthInsight(
                    type: .mood,
                    title: "Mood Improving!",
                    message: "Your check-in scores are getting better. Keep up the great work!",
                    trend: InsightTrend(percentage: "↑", isPositive: true)
                )
            } else if improvement < -3 {
                return HealthInsight(
                    type: .mood,
                    title: "Check In",
                    message: "Your scores suggest you might need extra support. Consider reaching out.",
                    trend: InsightTrend(percentage: "↓", isPositive: false)
                )
            }
        }
        
        if recentAvg < 5 {
            return HealthInsight(
                type: .mood,
                title: "Feeling Good!",
                message: "Your recent check-ins show you're doing well. Keep it up!",
                trend: nil
            )
        }
        
        return nil
    }
    
    private static func generateStreakInsight(currentStreak: Int) -> HealthInsight? {
        if currentStreak >= 7 {
            return HealthInsight(
                type: .celebration,
                title: "\(currentStreak) Day Streak!",
                message: "Consistency is key! You're building a powerful habit.",
                trend: nil
            )
        } else if currentStreak >= 3 {
            return HealthInsight(
                type: .celebration,
                title: "Building Momentum",
                message: "You're \(currentStreak) days in! Keep the streak alive.",
                trend: nil
            )
        }
        
        return nil
    }
    
    private static func generateHeartRateInsight(currentMetrics: [HealthMetric]) -> HealthInsight? {
        guard let heartRate = currentMetrics.first(where: { $0.type == .heartRate }) else {
            return nil
        }
        
        let hr = heartRate.value
        
        if hr >= 60 && hr <= 80 {
            return HealthInsight(
                type: .heart,
                title: "Healthy Heart Rate",
                message: "Your resting heart rate is in a healthy range. Great cardiovascular health!",
                trend: nil
            )
        } else if hr > 100 {
            return HealthInsight(
                type: .warning,
                title: "Elevated Heart Rate",
                message: "Your heart rate is higher than usual. Make sure to rest and stay hydrated.",
                trend: nil
            )
        }
        
        return nil
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        AIInsightsCard(insights: [
            HealthInsight(
                type: .activity,
                title: "Activity Boost!",
                message: "Your step count is up this week! Keep moving to maintain this momentum.",
                trend: InsightTrend(percentage: "+23%", isPositive: true)
            ),
            HealthInsight(
                type: .mood,
                title: "Mood Improving!",
                message: "Your check-in scores are getting better. Keep up the great work!",
                trend: InsightTrend(percentage: "↑", isPositive: true)
            ),
            HealthInsight(
                type: .celebration,
                title: "7 Day Streak!",
                message: "Consistency is key! You're building a powerful habit.",
                trend: nil
            )
        ])
        
        AIInsightsCard(insights: [])
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
