// Features/Dashboard/Core/Design System/Components/DSCard.swift
import SwiftUI

struct DSCard<Content: View>: View {
    let content: Content
    var style: CardStyle = .elevated
    var padding: CGFloat = DesignSystem.Spacing.medium
    
    enum CardStyle {
        case flat
        case elevated
        case highlighted
        case bordered
    }
    
    init(
        style: CardStyle = .elevated,
        padding: CGFloat = DesignSystem.Spacing.medium,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }
    
    // MARK: - Style Properties
    
    private var backgroundColor: Color {
        switch style {
        case .flat, .elevated, .bordered:
            return Color.ds.cardBackground
        case .highlighted:
            return Color.ds.accentLight
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .flat, .bordered:
            return Color.clear
        case .elevated:
            return Color.black.opacity(0.08)
        case .highlighted:
            return Color.ds.accent.opacity(0.15)
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .flat, .bordered:
            return 0
        case .elevated:
            return 8
        case .highlighted:
            return 12
        }
    }
    
    private var shadowY: CGFloat {
        switch style {
        case .flat, .bordered:
            return 0
        case .elevated:
            return 4
        case .highlighted:
            return 6
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .bordered:
            return Color.ds.border
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        style == .bordered ? 1 : 0
    }
}

// MARK: - Convenience View Extensions

extension View {
    func cardStyle(_ style: DSCard<EmptyView>.CardStyle = .elevated, padding: CGFloat = DesignSystem.Spacing.medium) -> some View {
        DSCard(style: style, padding: padding) {
            self as! EmptyView
        }
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            // Elevated Card
            DSCard(style: .elevated) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Elevated Card")
                        .font(.ds.headline)
                    Text("This card has a subtle shadow")
                        .font(.ds.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Flat Card
            DSCard(style: .flat) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Flat Card")
                        .font(.ds.headline)
                    Text("No shadow, clean look")
                        .font(.ds.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Highlighted Card
            DSCard(style: .highlighted) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Highlighted Card")
                        .font(.ds.headline)
                    Text("Draws attention with accent color")
                        .font(.ds.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Bordered Card
            DSCard(style: .bordered) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Bordered Card")
                        .font(.ds.headline)
                    Text("Clear border, no shadow")
                        .font(.ds.body)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Using convenience modifier
            VStack(alignment: .leading, spacing: 8) {
                Text("Using Modifier")
                    .font(.ds.headline)
                Text("Applied with .cardStyle() modifier")
                    .font(.ds.body)
                    .foregroundStyle(.secondary)
            }
            .cardStyle(.elevated)
        }
        .padding()
    }
    .background(Color.ds.backgroundPrimary)
}
