import SwiftUI

// Enhanced metric card with gradient and animations
struct EnhancedMetricCard: View {
    let metric: HealthMetric
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(metric.type.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: metric.type.icon)
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(metric.type.color.gradient)
                        .symbolRenderingMode(.hierarchical)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(metric.type.color)
                    .opacity(0.7)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(metric.type.rawValue)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(metric.formattedValue)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(metric.type.color.gradient)
                    
                    if !metric.type.unit.isEmpty {
                        Text(metric.type.unit)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(metric.type.color.opacity(0.2), lineWidth: 1)
                }
                .shadow(color: metric.type.color.opacity(0.1), radius: 8, y: 4)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
    }
}

// Gradient progress card
struct GradientProgressCard: View {
    let title: String
    let value: Double
    let goal: Double
    let icon: String
    let gradient: LinearGradient
    
    var progress: Double {
        min(value / goal, 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(gradient)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(gradient)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                
                ProgressView(value: progress)
                    .tint(gradient)
                    .scaleEffect(y: 2, anchor: .center)
                
                HStack {
                    Text("\(Int(value))")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("/ \(Int(goal))")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(gradient, lineWidth: 1.5)
                        .opacity(0.3)
                }
        }
    }
}

// Stats card with trend
struct StatsTrendCard: View {
    let title: String
    let value: String
    let subtitle: String
    let trend: Double
    let icon: String
    let color: Color
    
    var trendIcon: String {
        trend > 0 ? "arrow.up.right" : trend < 0 ? "arrow.down.right" : "minus"
    }
    
    var trendColor: Color {
        trend > 0 ? .green : trend < 0 ? .red : .gray
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: trendIcon)
                        .font(.system(size: 12, weight: .bold))
                    Text("\(abs(Int(trend)))%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(trendColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background {
                    Capsule()
                        .fill(trendColor.opacity(0.15))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: color.opacity(0.1), radius: 10, y: 5)
        }
    }
}

// Compact metric row
struct CompactMetricRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(color.gradient)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)
                .opacity(0.5)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            EnhancedMetricCard(metric: HealthMetric.mock[0])
            
            GradientProgressCard(
                title: "Daily Steps",
                value: 8543,
                goal: 10000,
                icon: "figure.walk.circle.fill",
                gradient: LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            
            StatsTrendCard(
                title: "Mood Score",
                value: "8.2",
                subtitle: "Better than yesterday",
                trend: 12,
                icon: "face.smiling.fill",
                color: .green
            )
            
            CompactMetricRow(icon: "heart.fill", title: "Heart Rate", value: "72 bpm", color: .red)
        }
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
