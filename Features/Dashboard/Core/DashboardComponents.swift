// Features/Dashboard/Core/DashboardComponents.swift
import SwiftUI

// MARK: - Streak Badge View
struct StreakBadgeView: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                Text("\(currentStreak)")
                    .font(.system(.title3, design: .rounded).weight(.bold))
            }
            
            Text("day streak")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Improved Metric Card
struct ImprovedMetricCard: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: metric.type.systemImageName)
                    .font(.system(size: 20))
                    .foregroundStyle(metric.type.color)
                    .frame(width: 32, height: 32)
                    .background(metric.type.color.opacity(0.15))
                    .clipShape(Circle())
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.type.rawValue)
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(metric.formattedValue)
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text(metric.type.unit)
                        .font(.ds.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Chart Card
struct ChartCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let isLoading: Bool
    let isEmpty: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Spacer()
            }
            
            if isLoading {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemGray6))
                    .frame(height: 140)
                    .overlay(ProgressView())
            } else if isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    Text("No data available")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Color(UIColor.tertiarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                content()
                    .padding(8)
                    .background(Color(UIColor.tertiarySystemGroupedBackground).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Extensions (removed - now in HealthMetric.swift)

// MARK: - Previews
#Preview("Streak Badge") {
    VStack(spacing: 20) {
        StreakBadgeView(currentStreak: 7, longestStreak: 14)
        StreakBadgeView(currentStreak: 1, longestStreak: 1)
        StreakBadgeView(currentStreak: 30, longestStreak: 45)
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}

#Preview("Metric Card") {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
        ImprovedMetricCard(metric: HealthMetric(type: .heartRate, value: 72, date: Date()))
        ImprovedMetricCard(metric: HealthMetric(type: .steps, value: 8543, date: Date()))
        ImprovedMetricCard(metric: HealthMetric(type: .calories, value: 342, date: Date()))
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
