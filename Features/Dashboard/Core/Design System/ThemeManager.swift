// Features/Dashboard/Core/Design System/ThemeManager.swift
import SwiftUI
import Combine

enum AppStyle: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case coffee = "Coffee"
    var id: String { self.rawValue }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @AppStorage("app_style") var currentStyle: AppStyle = .classic
    
    private init() {
        // Force classic for now as requested
        self.currentStyle = .classic
    }
    
    // MARK: - Colors
    
    func color(for key: ColorKey) -> Color {
        switch currentStyle {
        case .classic:
            return classicColor(for: key)
        case .coffee:
            return coffeeColor(for: key)
        }
    }
    
    private func classicColor(for key: ColorKey) -> Color {
        switch key {
        case .backgroundPrimary: return Color("BackgroundPrimary")
        case .backgroundSecondary: return Color(UIColor.secondarySystemBackground)
        case .cardBackground: return Color(UIColor.secondarySystemGroupedBackground)
        case .textPrimary: return Color("TextPrimary")
        case .accent: return Color("Accent")
        case .success: return Color(hex: "#4CAF50")
        case .error: return Color(hex: "#EF5350")
        case .warning: return Color(hex: "#FF9800")
        }
    }
    
    private func coffeeColor(for key: ColorKey) -> Color {
        switch key {
        case .backgroundPrimary: return Color(hex: "#F5F5DC")
        case .backgroundSecondary: return Color(hex: "#F5F5DC").opacity(0.8)
        case .cardBackground: return Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(Color(hex: "#2B1B12")) : .secondarySystemGroupedBackground
        })
        case .textPrimary: return Color(hex: "#3E2723")
        case .accent: return Color(hex: "#3E2723")
        case .success: return Color(hex: "#8DA399")
        case .error: return Color(hex: "#D2691E")
        case .warning: return Color(hex: "#D2691E")
        }
    }
    
    // MARK: - Icons
    
    func icon(for key: IconKey) -> String {
        switch currentStyle {
        case .classic:
            return classicIcon(for: key)
        case .coffee:
            return coffeeIcon(for: key)
        }
    }
    
    private func classicIcon(for key: IconKey) -> String {
        switch key {
        case .home: return "house.fill"
        case .journal: return "book.closed.fill"
        case .community: return "person.3.fill"
        case .insights: return "chart.xyaxis.line"
        case .support: return "lifepreserver.fill"
        case .streak: return "flame.fill"
        case .emptyState: return "text.bubble"
        case .errorState: return "exclamationmark.triangle"
        case .successState: return "checkmark.seal.fill"
        }
    }
    
    private func coffeeIcon(for key: IconKey) -> String {
        let custom = "custom:"
        switch key {
        case .home: return "\(custom)tab-mug-icon"
        case .journal: return "\(custom)tab-notebook-icon"
        case .community: return "\(custom)tab-table-icon"
        case .insights: return "\(custom)tab-chart-drops-icon"
        case .support: return "\(custom)tab-grinder-icon"
        case .streak: return "\(custom)icon-coffee-bean"
        case .emptyState: return "\(custom)illu-empty-table"
        case .errorState: return "\(custom)illu-error-spill"
        case .successState: return "\(custom)illu-success-latte"
        }
    }
}

enum ColorKey {
    case backgroundPrimary, backgroundSecondary, cardBackground
    case textPrimary, accent
    case success, error, warning
}

enum IconKey {
    case home, journal, community, insights, support
    case streak, emptyState, errorState, successState
}
