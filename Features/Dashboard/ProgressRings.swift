// Features/Dashboard/ProgressRings.swift
import SwiftUI

struct ProgressRingsView: View {
    let stepsProgress: Double // 0.0 to 1.0
    let caloriesProgress: Double
    let heartRateProgress: Double
    
    let stepsGoal: Int
    let caloriesGoal: Int
    let heartRateGoal: Int
    
    let currentSteps: Int
    let currentCalories: Int
    let currentHeartRate: Int
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.medium) {
            HStack {
                Text("Daily Goals")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                Spacer()
                
                // Overall completion badge
                Text("\(Int(averageProgress * 100))%")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(completionColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(completionColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: DesignSystem.Spacing.large) {
                // Main Progress Rings
                ZStack {
                    // Heart Rate Ring (Outer)
                    ProgressRing(
                        progress: heartRateProgress,
                        color: .pink,
                        lineWidth: 14
                    )
                    .frame(width: 170, height: 170)
                    
                    // Calories Ring (Middle)
                    ProgressRing(
                        progress: caloriesProgress,
                        color: .green,
                        lineWidth: 14
                    )
                    .frame(width: 128, height: 128)
                    
                    // Steps Ring (Inner)
                    ProgressRing(
                        progress: stepsProgress,
                        color: .ds.accent,
                        lineWidth: 14
                    )
                    .frame(width: 86, height: 86)
                    
                    // Center icon
                    Image(systemName: completionIcon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(completionColor)
                }
                .frame(maxWidth: .infinity)
                
                // Legend
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    ProgressLegendItem(
                        color: .ds.accent,
                        icon: "figure.walk",
                        title: "Steps",
                        current: currentSteps,
                        goal: stepsGoal,
                        progress: stepsProgress
                    )
                    
                    ProgressLegendItem(
                        color: .green,
                        icon: "flame.fill",
                        title: "Calories",
                        current: currentCalories,
                        goal: caloriesGoal,
                        progress: caloriesProgress
                    )
                    
                    ProgressLegendItem(
                        color: .pink,
                        icon: "heart.fill",
                        title: "Heart",
                        current: currentHeartRate,
                        goal: heartRateGoal,
                        progress: heartRateProgress
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
    }
    
    private var completionIcon: String {
        if averageProgress >= 1.0 {
            return "checkmark.circle.fill"
        } else if averageProgress >= 0.75 {
            return "star.fill"
        } else if averageProgress >= 0.5 {
            return "chart.bar.fill"
        } else {
            return "chart.bar"
        }
    }
    
    private var completionColor: Color {
        if averageProgress >= 1.0 {
            return .green
        } else if averageProgress >= 0.75 {
            return .orange
        } else {
            return .blue
        }
    }
    
    private var averageProgress: Double {
        (stepsProgress + caloriesProgress + heartRateProgress) / 3.0
    }
}

// Individual Progress Ring
struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // Progress ring
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color.gradient,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 1.0), value: progress)
        }
    }
}

// Legend Item
struct ProgressLegendItem: View {
    let color: Color
    let icon: String
    let title: String
    let current: Int
    let goal: Int
    let progress: Double
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ds.caption)
                    .foregroundStyle(.primary)
                
                HStack(spacing: 4) {
                    Text("\(current)")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(color)
                    Text("/ \(goal)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Text("\(Int(progress * 100))%")
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(progress >= 1.0 ? color : .secondary)
        }
    }
}

// Helper to calculate progress
struct ProgressGoals {
    static let defaultStepsGoal = 10000
    static let defaultCaloriesGoal = 500
    static let defaultHeartRateGoal = 75 // Average target
    
    static func calculateProgress(current: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(current / goal, 1.0)
    }
    
    static func stepsProgress(current: Double, goal: Int = defaultStepsGoal) -> Double {
        calculateProgress(current: current, goal: Double(goal))
    }
    
    static func caloriesProgress(current: Double, goal: Int = defaultCaloriesGoal) -> Double {
        calculateProgress(current: current, goal: Double(goal))
    }
    
    static func heartRateProgress(current: Double, goal: Int = defaultHeartRateGoal) -> Double {
        // For heart rate, being close to goal is good (not exceeding)
        guard goal > 0 else { return 0 }
        let difference = abs(current - Double(goal))
        let tolerance = Double(goal) * 0.2 // 20% tolerance
        
        if difference <= tolerance {
            return 1.0 // Perfect!
        } else {
            return max(0, 1.0 - (difference / Double(goal)))
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        // Full goals
        ProgressRingsView(
            stepsProgress: 0.85,
            caloriesProgress: 0.65,
            heartRateProgress: 0.92,
            stepsGoal: 10000,
            caloriesGoal: 500,
            heartRateGoal: 75,
            currentSteps: 8500,
            currentCalories: 325,
            currentHeartRate: 72
        )
        
        // Starting the day
        ProgressRingsView(
            stepsProgress: 0.15,
            caloriesProgress: 0.08,
            heartRateProgress: 0.45,
            stepsGoal: 10000,
            caloriesGoal: 500,
            heartRateGoal: 75,
            currentSteps: 1500,
            currentCalories: 40,
            currentHeartRate: 68
        )
        
        // Goals achieved!
        ProgressRingsView(
            stepsProgress: 1.0,
            caloriesProgress: 1.0,
            heartRateProgress: 1.0,
            stepsGoal: 10000,
            caloriesGoal: 500,
            heartRateGoal: 75,
            currentSteps: 12000,
            currentCalories: 550,
            currentHeartRate: 75
        )
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
