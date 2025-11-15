//
//  DS+Spacing.swift
//  Depresso
//
//  Created by ElAmir Mansour on 03/10/2025.
//

import Foundation

extension DesignSystem {
    enum Spacing {
        /// 2 points - Tight spacing
        static let xxxSmall: CGFloat = 2.0
        /// 4 points
        static let xxSmall: CGFloat = 4.0
        /// 6 points - Between elements
        static let extraSmall: CGFloat = 6.0
        /// 8 points
        static let small: CGFloat = 8.0
        /// 12 points
        static let mediumSmall: CGFloat = 12.0
        /// 16 points
        static let medium: CGFloat = 16.0
        /// 20 points
        static let mediumLarge: CGFloat = 20.0
        /// 24 points
        static let large: CGFloat = 24.0
        /// 32 points
        static let extraLarge: CGFloat = 32.0
        /// 40 points - Section spacing
        static let xxLarge: CGFloat = 40.0
        /// 48 points - Screen margins
        static let xxxLarge: CGFloat = 48.0
    }
    
    enum CornerRadius {
        /// 8 points
        static let small: CGFloat = 8.0
        /// 12 points
        static let medium: CGFloat = 12.0
        /// 16 points
        static let large: CGFloat = 16.0
        /// 20 points
        static let extraLarge: CGFloat = 20.0
        /// 24 points
        static let xxLarge: CGFloat = 24.0
        /// 999 points - Pill shape
        static let pill: CGFloat = 999.0
    }
}
