// Features/Dashboard/Core/Design System/DS+Typography.swift
import SwiftUI

extension Font {
    /// The Design System's fonts.
    static let ds = DSTypography()
}

struct DSTypography {
    // Display (Marketing/Splash)
    let displayXL = Font.system(size: 64, weight: .bold, design: .rounded)
    let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)
    let displaySmall = Font.system(size: 28, weight: .bold, design: .rounded)
    
    // Titles
    let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    let title1 = Font.largeTitle.weight(.bold)
    let title = Font.largeTitle.weight(.bold)
    let title2 = Font.title.weight(.bold)
    let title3 = Font.title2.weight(.semibold)
    
    // Body
    let bodyLarge = Font.title3.weight(.regular)
    let body = Font.body
    let bodySmall = Font.callout
    
    // Labels
    let headline = Font.headline.weight(.semibold)
    let subheadline = Font.subheadline
    let caption = Font.caption
    let caption2 = Font.caption2
    let caption3 = Font.system(size: 11)
    let footnote = Font.footnote
    
    // Special
    let number = Font.system(.body, design: .rounded).weight(.semibold)
    let monospaced = Font.system(.body, design: .monospaced)
}
