// Features/Dashboard/Core/Design System/DS+Color.swift
import SwiftUI

// Define a namespace for our design system
enum DesignSystem { }

extension Color {
    /// The Design System's colors.
    static var ds: DSColor { DSColor() }
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct DSColor {
    private let theme = ThemeManager.shared
    
    // Backgrounds
    var backgroundPrimary: Color { theme.color(for: .backgroundPrimary) }
    var backgroundSecondary: Color { theme.color(for: .backgroundSecondary) }
    var cardBackground: Color { theme.color(for: .cardBackground) }
    
    // Text
    var textPrimary: Color { theme.color(for: .textPrimary) }
    var textSecondary: Color { theme.color(for: .textPrimary).opacity(0.7) }
    var textTertiary: Color { theme.color(for: .textPrimary).opacity(0.5) }
    
    // Accents
    var accent: Color { theme.color(for: .accent) }
    var accentLight: Color { theme.color(for: .accent).opacity(0.15) }
    var accentDark: Color { theme.color(for: .accent).opacity(0.8) }
    
    // Semantic Colors
    var success: Color { theme.color(for: .success) }
    var error: Color { theme.color(for: .error) }
    var warning: Color { theme.color(for: .warning) }
    
    // Enhanced backgrounds
    var successBackground: Color { theme.color(for: .success).opacity(0.1) }
    var errorBackground: Color { theme.color(for: .error).opacity(0.1) }
    var warningBackground: Color { theme.color(for: .warning).opacity(0.1) }
    
    var border: Color { theme.color(for: .textPrimary).opacity(0.1) }
    var disabled: Color { theme.color(for: .textPrimary).opacity(0.3) }
}
