// Features/Dashboard/Core/Design System/DS+Color.swift
import SwiftUI

// Define a namespace for our design system
enum DesignSystem { }

extension Color {
    /// The Design System's colors.
    static let ds = DSColor()
    
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
    // Backgrounds
    let backgroundPrimary = Color("BackgroundPrimary")
    let backgroundSecondary = Color(UIColor.secondarySystemBackground)
    let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    
    // Text
    let textPrimary = Color("TextPrimary")
    let textSecondary = Color.secondary
    let textTertiary = Color.gray
    
    // Accents
    let accent = Color("Accent")
    let accentLight = Color("Accent").opacity(0.15)
    let accentDark = Color("Accent").opacity(0.8)
    
    // Semantic Colors (Enhanced for better UX feedback)
    let success = Color(hex: "#4CAF50")
    let error = Color(hex: "#EF5350")
    let warning = Color(hex: "#FF9800")
    let info = Color(hex: "#2196F3")
    
    // Status Colors (from UX recommendations)
    let positiveGreen = Color(hex: "#4CAF50")
    let negativeRed = Color(hex: "#EF5350")
    let neutralGray = Color(hex: "#9E9E9E")
    
    // States
    let disabled = Color.gray.opacity(0.5)
    let border = Color.gray.opacity(0.2)
    
    // Enhanced backgrounds
    let overlayBackground = Color.black.opacity(0.4)
    let successBackground = Color(hex: "#4CAF50").opacity(0.1)
    let errorBackground = Color(hex: "#EF5350").opacity(0.1)
    let warningBackground = Color(hex: "#FF9800").opacity(0.1)
}
