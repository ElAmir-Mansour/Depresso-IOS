// In Features/Dashboard/HealthMetric.swift
import Foundation
import SwiftUI

enum HealthMetricType: String, CaseIterable, Identifiable {
    case steps = "Steps"
    case calories = "Calories"
    case heartRate = "Heart Rate"
    case sleepHours = "Sleep"
    case activeEnergy = "Active Energy"
    case distance = "Distance"
    case flightsClimbed = "Flights Climbed"
    case exerciseTime = "Exercise"
    case standHours = "Stand Hours"
    case restingHeartRate = "Resting HR"
    case heartRateVariability = "HRV"
    case vo2Max = "VO2 Max"
    case walkingRunningDistance = "Walk+Run"
    case cyclingDistance = "Cycling"
    case swimmingDistance = "Swimming"
    case respiratoryRate = "Breathing"
    case bodyMass = "Weight"
    case bodyFatPercentage = "Body Fat"
    case leanBodyMass = "Lean Mass"
    case mindfulMinutes = "Mindfulness"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .steps: return "figure.walk.circle.fill"
        case .calories: return "flame.circle.fill"
        case .heartRate: return "waveform.path.ecg.rectangle.fill"
        case .sleepHours: return "bed.double.fill"
        case .activeEnergy: return "bolt.circle.fill"
        case .distance: return "figure.run.circle.fill"
        case .flightsClimbed: return "figure.stairs.circle.fill"
        case .exerciseTime: return "figure.strengthtraining.traditional"
        case .standHours: return "figure.stand.circle.fill"
        case .restingHeartRate: return "heart.circle.fill"
        case .heartRateVariability: return "waveform.path"
        case .vo2Max: return "lungs.fill"
        case .walkingRunningDistance: return "figure.walk"
        case .cyclingDistance: return "bicycle.circle.fill"
        case .swimmingDistance: return "figure.pool.swim"
        case .respiratoryRate: return "wind"
        case .bodyMass: return "scalemass.fill"
        case .bodyFatPercentage: return "percent"
        case .leanBodyMass: return "figure.arms.open"
        case .mindfulMinutes: return "brain.head.profile"
        }
    }
    
    var systemImageName: String {
        return icon
    }
    
    var color: Color {
        switch self {
        case .steps: return .blue
        case .calories: return .orange
        case .heartRate: return .red
        case .sleepHours: return .purple
        case .activeEnergy: return .green
        case .distance: return .cyan
        case .flightsClimbed: return .indigo
        case .exerciseTime: return .pink
        case .standHours: return .teal
        case .restingHeartRate: return Color(red: 0.8, green: 0.2, blue: 0.2)
        case .heartRateVariability: return Color(red: 0.6, green: 0.2, blue: 0.8)
        case .vo2Max: return Color(red: 0.2, green: 0.6, blue: 0.8)
        case .walkingRunningDistance: return .mint
        case .cyclingDistance: return .yellow
        case .swimmingDistance: return .blue
        case .respiratoryRate: return Color(red: 0.4, green: 0.7, blue: 0.9)
        case .bodyMass: return .brown
        case .bodyFatPercentage: return .orange
        case .leanBodyMass: return .green
        case .mindfulMinutes: return Color(red: 0.5, green: 0.3, blue: 0.7)
        }
    }
    
    var unit: String {
         switch self {
         case .steps: return "steps"
         case .calories: return "kcal"
         case .heartRate: return "bpm"
         case .sleepHours: return "hrs"
         case .activeEnergy: return "cal"
         case .distance: return "km"
         case .flightsClimbed: return "flights"
         case .exerciseTime: return "min"
         case .standHours: return "hrs"
         case .restingHeartRate: return "bpm"
         case .heartRateVariability: return "ms"
         case .vo2Max: return "ml/kg/min"
         case .walkingRunningDistance: return "km"
         case .cyclingDistance: return "km"
         case .swimmingDistance: return "m"
         case .respiratoryRate: return "br/min"
         case .bodyMass: return "kg"
         case .bodyFatPercentage: return "%"
         case .leanBodyMass: return "kg"
         case .mindfulMinutes: return "min"
         }
     }
}

struct HealthMetric: Identifiable, Equatable {
    let id = UUID()
    let type: HealthMetricType
    let value: Double
    let date: Date
    
    static var mock: [HealthMetric] {
         [
             .init(type: .steps, value: Double.random(in: 3000...12000), date: .now),
             .init(type: .calories, value: Double.random(in: 150...600), date: .now),
             .init(type: .heartRate, value: Double.random(in: 60...90), date: .now),
             .init(type: .sleepHours, value: Double.random(in: 5...9), date: .now),
             .init(type: .activeEnergy, value: Double.random(in: 200...800), date: .now),
             .init(type: .distance, value: Double.random(in: 2...10), date: .now),
             .init(type: .flightsClimbed, value: Double.random(in: 5...20), date: .now),
             .init(type: .exerciseTime, value: Double.random(in: 15...90), date: .now),
             .init(type: .standHours, value: Double.random(in: 6...12), date: .now),
             .init(type: .restingHeartRate, value: Double.random(in: 50...70), date: .now),
             .init(type: .heartRateVariability, value: Double.random(in: 20...80), date: .now),
             .init(type: .vo2Max, value: Double.random(in: 30...50), date: .now)
         ]
     }
    
    var formattedValue: String {
        switch type {
        case .steps, .flightsClimbed:
            return String(format: "%.0f", value)
        case .calories, .activeEnergy, .exerciseTime, .mindfulMinutes:
            return String(format: "%.0f", value)
        case .heartRate, .restingHeartRate, .respiratoryRate:
            return String(format: "%.0f", value)
        case .sleepHours, .standHours, .distance, .walkingRunningDistance, .cyclingDistance:
            return String(format: "%.1f", value)
        case .heartRateVariability, .vo2Max:
            return String(format: "%.1f", value)
        case .swimmingDistance, .bodyMass, .leanBodyMass:
            return String(format: "%.1f", value)
        case .bodyFatPercentage:
            return String(format: "%.1f", value)
        }
    }
    
    var displayValue: String {
        return formattedValue
    }
}

// ✅ Defined MetricCardView struct
struct MetricCardView: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            HStack {
                Image(systemName: metric.type.systemImageName)
                    .foregroundStyle(Color.ds.accent)
                Text(metric.type.rawValue)
                    .font(.ds.caption)
                Spacer()
            }
            HStack(alignment: .lastTextBaseline) {
                 Text(metric.formattedValue)
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                 Text(metric.type.unit)
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
