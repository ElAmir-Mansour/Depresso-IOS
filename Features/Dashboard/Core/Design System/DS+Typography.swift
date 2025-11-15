//
//  DS+Typography.swift
//  Depresso
//
//  Created by ElAmir Mansour on 03/10/2025.
//

// In Core/DesignSystem/DS+Typography.swift
import SwiftUI

extension Font {
    /// The Design System's fonts.
    static let ds = DSTypography()
}

struct DSTypography {
    // Display (Marketing/Splash)
    let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
    let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)
    
    // Titles
    let title = Font.largeTitle.weight(.bold)
    let title2 = Font.title.weight(.bold)
    let title3 = Font.title2.weight(.semibold)
    
    // Body
    let bodyLarge = Font.body.weight(.medium)
    let body = Font.body
    let bodySmall = Font.callout
    
    // Labels
    let headline = Font.headline.weight(.semibold)
    let subheadline = Font.subheadline
    let caption = Font.caption
    let caption2 = Font.caption2
    let footnote = Font.footnote
    
    // Special
    let number = Font.system(.body, design: .rounded).weight(.semibold)
    let monospaced = Font.system(.body, design: .monospaced)
}