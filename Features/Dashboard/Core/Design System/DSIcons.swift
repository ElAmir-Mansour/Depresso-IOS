// Features/Dashboard/Core/Design System/DSIcons.swift
import SwiftUI

// Depresso Dynamic Icon System
enum DSIcons {
    private static let custom = "custom:"
    private static let theme = ThemeManager.shared
    
    // Navigation (Tab Bar)
    static var home: String { theme.icon(for: .home) }
    static var journal: String { theme.icon(for: .journal) }
    static var community: String { theme.icon(for: .community) }
    static var insights: String { theme.icon(for: .insights) }
    static var support: String { theme.icon(for: .support) }
    
    // Gamification & Streaks
    static var streak: String { theme.icon(for: .streak) }
    static var bean: String { "custom:icon-coffee-bean" }
    static var fire: String { "flame.fill" }
    
    // Feedback Illustrations
    static var emptyState: String { theme.icon(for: .emptyState) }
    static var errorState: String { theme.icon(for: .errorState) }
    static var successState: String { theme.icon(for: .successState) }
    
    // --- SF Symbols fallback ---
    static let heart = "heart.fill"
    static let heartbeat = "waveform.path.ecg.rectangle.fill"
    static let steps = "figure.walk.circle.fill"
    static let sleep = "bed.double.fill"
    static let energy = "bolt.circle.fill"
    static let activity = "flame.circle.fill"
    static let mood = "face.smiling.fill"
    static let settings = "gearshape.2.fill"
    static let info = "info.circle.fill"
    static let warning = "exclamationmark.triangle.fill"
    static let bell = "bell.badge.fill"
    static let share = "square.and.arrow.up.circle.fill"
    
    // Helper to determine if an icon is custom
    static func isCustom(_ name: String) -> Bool {
        name.hasPrefix(custom)
    }
    
    // Helper to get the actual name (strips prefix)
    static func actualName(_ name: String) -> String {
        if name.hasPrefix(custom) {
            return String(name.dropFirst(custom.count))
        }
        return name
    }
}

// Icon View - Handles both SF Symbols and Custom SVGs
struct DSIcon: View {
    let name: String
    let color: Color
    let size: CGFloat
    let weight: Font.Weight
    let animated: Bool
    
    @State private var isAnimating = false
    
    init(
        _ name: String, 
        color: Color = .primary, 
        size: CGFloat = 20,
        weight: Font.Weight = .semibold,
        animated: Bool = false
    ) {
        self.name = name
        self.color = color
        self.size = size
        self.weight = weight
        self.animated = animated
    }
    
    var body: some View {
        Group {
            if DSIcons.isCustom(name) {
                Image(DSIcons.actualName(name))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .foregroundStyle(color)
            } else {
                Image(systemName: name)
                    .font(.system(size: size, weight: weight, design: .rounded))
                    .foregroundStyle(color.gradient)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .scaleEffect(isAnimating && animated ? 1.1 : 1.0)
        .animation(
            animated ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : nil,
            value: isAnimating
        )
        .onAppear {
            if animated {
                isAnimating = true
            }
        }
    }
}
