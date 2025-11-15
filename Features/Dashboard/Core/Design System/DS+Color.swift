//
//  DS+Color.swift
//  Depresso
//
//  Created by ElAmir Mansour on 03/10/2025.
//
// In Core/DesignSystem/DS+Color.swift
import SwiftUI

// Define a namespace for our design system
enum DesignSystem { }

extension Color {
    /// The Design System's colors.
    static let ds = DSColor()
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
    let accentLight = Color("Accent").opacity(0.2)
    let accentDark = Color("Accent").opacity(0.8)
    
    // Semantic Colors
    let success = Color.green
    let error = Color.red
    let warning = Color.orange
    let info = Color.blue
    
    // States
    let disabled = Color.gray.opacity(0.5)
    let border = Color.gray.opacity(0.2)
}