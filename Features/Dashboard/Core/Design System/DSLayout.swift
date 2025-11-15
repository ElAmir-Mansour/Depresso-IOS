// DSLayout.swift - Enhanced layout system for consistent spacing and structure

import SwiftUI

enum DSLayout {
    // MARK: - Card Layouts
    static let cardCornerRadius: CGFloat = 16
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2
    
    // MARK: - Section Spacing
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 16
    static let compactSpacing: CGFloat = 12
    
    // MARK: - Padding
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let buttonPadding: CGFloat = 16
    
    // MARK: - Sizes
    static let iconSize: CGFloat = 24
    static let smallIconSize: CGFloat = 20
    static let heroIconSize: CGFloat = 48
    
    // MARK: - Heights
    static let buttonHeight: CGFloat = 50
    static let compactButtonHeight: CGFloat = 44
    static let chartHeight: CGFloat = 200
    static let compactChartHeight: CGFloat = 150
}

// MARK: - Layout Modifiers
extension View {
    func cardStyle() -> some View {
        self
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: DSLayout.cardCornerRadius))
            .shadow(color: .black.opacity(0.05), radius: DSLayout.cardShadowRadius, x: 0, y: DSLayout.cardShadowY)
    }
    
    func sectionContainer() -> some View {
        self
            .padding(.horizontal, DSLayout.screenPadding)
    }
}
