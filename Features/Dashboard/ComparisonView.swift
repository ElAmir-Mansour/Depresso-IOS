// Features/Dashboard/ComparisonView.swift
import SwiftUI

struct WeeklyComparisonCard: View {
    let comparison: WeeklyComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("This Week vs Last Week")
                    .font(.ds.headline)
                Spacer()
            }
            
            VStack(spacing: DesignSystem.Spacing.small) {
                ComparisonRow(
                    icon: "figure.walk",
                    color: .blue,
                    title: "Steps",
                    thisWeek: comparison.thisWeekSteps,
                    lastWeek: comparison.lastWeekSteps,
                    unit: ""
                )
                
                ComparisonRow(
                    icon: "flame.fill",
                    color: .orange,
                    title: "Calories",
                    thisWeek: comparison.thisWeekCalories,
                    lastWeek: comparison.lastWeekCalories,
                    unit: "kcal"
                )
                
                ComparisonRow(
                    icon: "heart.fill",
                    color: .pink,
                    title: "Avg Heart Rate",
                    thisWeek: comparison.thisWeekHeartRate,
                    lastWeek: comparison.lastWeekHeartRate,
                    unit: "bpm"
                )
                
                if let moodComparison = comparison.moodComparison {
                    ComparisonRow(
                        icon: "face.smiling",
                        color: .purple,
                        title: "Mood Score",
                        thisWeek: moodComparison.thisWeek,
                        lastWeek: moodComparison.lastWeek,
                        unit: "",
                        isLowerBetter: true
                    )
                }
            }
            
            // Overall summary
            if let summary = comparison.overallSummary {
                HStack {
                    Image(systemName: summary.isImproving ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(summary.isImproving ? .green : .orange)
                    
                    Text(summary.message)
                        .font(.ds.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, DesignSystem.Spacing.small)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct ComparisonRow: View {
    let icon: String
    let color: Color
    let title: String
    let thisWeek: Double
    let lastWeek: Double
    let unit: String
    var isLowerBetter: Bool = false
    
    var difference: Double {
        thisWeek - lastWeek
    }
    
    var percentageChange: Double {
        guard lastWeek > 0 else { return 0 }
        return (difference / lastWeek) * 100
    }
    
    var isImproving: Bool {
        isLowerBetter ? difference < 0 : difference > 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            
            // Title and values
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.ds.caption)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 12) {
                    // This week
                    HStack(spacing: 4) {
                        Text("Now:")
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                        Text("\(Int(thisWeek))\(unit)")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(color)
                    }
                    
                    // Last week
                    HStack(spacing: 4) {
                        Text("Was:")
                            .font(.system(.caption2))
                            .foregroundStyle(.secondary)
                        Text("\(Int(lastWeek))\(unit)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Change indicator
            if abs(percentageChange) > 1 {
                VStack(spacing: 2) {
                    Image(systemName: isImproving ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(isImproving ? .green : .red)
                    
                    Text("\(Int(abs(percentageChange)))%")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundStyle(isImproving ? .green : .red)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((isImproving ? Color.green : Color.red).opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text("—")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Models

struct WeeklyComparison {
    let thisWeekSteps: Double
    let lastWeekSteps: Double
    let thisWeekCalories: Double
    let lastWeekCalories: Double
    let thisWeekHeartRate: Double
    let lastWeekHeartRate: Double
    let moodComparison: MoodComparison?
    let overallSummary: ComparisonSummary?
    
    struct MoodComparison {
        let thisWeek: Double
        let lastWeek: Double
    }
    
    struct ComparisonSummary {
        let message: String
        let isImproving: Bool
    }
}

// MARK: - Comparison Calculator

struct ComparisonCalculator {
    static func calculateWeeklyComparison(
        weeklySteps: [StepData],
        weeklyEnergy: [EnergyData],
        weeklyHeartRate: [HeartRateData],
        assessmentHistory: [DailyAssessment]
    ) -> WeeklyComparison? {
        guard weeklySteps.count >= 7 else { return nil }
        
        // Split data into this week and last week
        let thisWeekSteps = Array(weeklySteps.suffix(7))
        let lastWeekSteps = Array(weeklySteps.dropLast(7).suffix(7))
        
        let thisWeekEnergy = Array(weeklyEnergy.suffix(7))
        let lastWeekEnergy = Array(weeklyEnergy.dropLast(7).suffix(7))
        
        let thisWeekHR = Array(weeklyHeartRate.suffix(7))
        let lastWeekHR = Array(weeklyHeartRate.dropLast(7).suffix(7))
        
        // Calculate averages
        let thisWeekStepsAvg = calculateAverage(thisWeekSteps.map(\.count))
        let lastWeekStepsAvg = lastWeekSteps.isEmpty ? 0 : calculateAverage(lastWeekSteps.map(\.count))
        
        let thisWeekCaloriesAvg = calculateAverage(thisWeekEnergy.map(\.value))
        let lastWeekCaloriesAvg = lastWeekEnergy.isEmpty ? 0 : calculateAverage(lastWeekEnergy.map(\.value))
        
        let thisWeekHRAvg = calculateAverage(thisWeekHR.map(\.value))
        let lastWeekHRAvg = lastWeekHR.isEmpty ? 0 : calculateAverage(lastWeekHR.map(\.value))
        
        // Mood comparison
        let moodComparison = calculateMoodComparison(assessmentHistory: assessmentHistory)
        
        // Overall summary
        let summary = generateSummary(
            stepsChange: thisWeekStepsAvg - lastWeekStepsAvg,
            caloriesChange: thisWeekCaloriesAvg - lastWeekCaloriesAvg,
            moodChange: moodComparison.map { $0.lastWeek - $0.thisWeek }
        )
        
        return WeeklyComparison(
            thisWeekSteps: thisWeekStepsAvg,
            lastWeekSteps: lastWeekStepsAvg,
            thisWeekCalories: thisWeekCaloriesAvg,
            lastWeekCalories: lastWeekCaloriesAvg,
            thisWeekHeartRate: thisWeekHRAvg,
            lastWeekHeartRate: lastWeekHRAvg,
            moodComparison: moodComparison,
            overallSummary: summary
        )
    }
    
    private static func calculateAverage(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private static func calculateMoodComparison(assessmentHistory: [DailyAssessment]) -> WeeklyComparison.MoodComparison? {
        guard assessmentHistory.count >= 7 else { return nil }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today)!
        
        let thisWeek = assessmentHistory.filter { $0.date >= oneWeekAgo && $0.date < today }
        let lastWeek = assessmentHistory.filter { $0.date >= twoWeeksAgo && $0.date < oneWeekAgo }
        
        guard !thisWeek.isEmpty, !lastWeek.isEmpty else { return nil }
        
        let thisWeekAvg = calculateAverage(thisWeek.map { Double($0.score) })
        let lastWeekAvg = calculateAverage(lastWeek.map { Double($0.score) })
        
        return WeeklyComparison.MoodComparison(
            thisWeek: thisWeekAvg,
            lastWeek: lastWeekAvg
        )
    }
    
    private static func generateSummary(
        stepsChange: Double,
        caloriesChange: Double,
        moodChange: Double?
    ) -> WeeklyComparison.ComparisonSummary {
        var improvementCount = 0
        var totalMetrics = 2
        
        if stepsChange > 0 { improvementCount += 1 }
        if caloriesChange > 0 { improvementCount += 1 }
        
        if let moodChange = moodChange {
            totalMetrics += 1
            if moodChange > 0 { improvementCount += 1 }
        }
        
        let improvementPercentage = Double(improvementCount) / Double(totalMetrics)
        
        let message: String
        let isImproving: Bool
        
        if improvementPercentage >= 0.66 {
            message = "Great progress this week! Keep up the momentum! 🚀"
            isImproving = true
        } else if improvementPercentage >= 0.33 {
            message = "Mixed results. Focus on consistency this week! 💪"
            isImproving = true
        } else {
            message = "Take it easy. Small steps lead to big changes! 🌱"
            isImproving = false
        }
        
        return WeeklyComparison.ComparisonSummary(
            message: message,
            isImproving: isImproving
        )
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        WeeklyComparisonCard(comparison: WeeklyComparison(
            thisWeekSteps: 8500,
            lastWeekSteps: 7200,
            thisWeekCalories: 425,
            lastWeekCalories: 380,
            thisWeekHeartRate: 72,
            lastWeekHeartRate: 75,
            moodComparison: WeeklyComparison.MoodComparison(
                thisWeek: 8,
                lastWeek: 12
            ),
            overallSummary: WeeklyComparison.ComparisonSummary(
                message: "Great progress this week! Keep up the momentum! 🚀",
                isImproving: true
            )
        ))
        
        WeeklyComparisonCard(comparison: WeeklyComparison(
            thisWeekSteps: 6200,
            lastWeekSteps: 8500,
            thisWeekCalories: 320,
            lastWeekCalories: 450,
            thisWeekHeartRate: 78,
            lastWeekHeartRate: 72,
            moodComparison: nil,
            overallSummary: WeeklyComparison.ComparisonSummary(
                message: "Take it easy. Small steps lead to big changes! 🌱",
                isImproving: false
            )
        ))
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
