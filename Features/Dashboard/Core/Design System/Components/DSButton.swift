// Features/Dashboard/Core/Design System/Components/DSButton.swift
import SwiftUI

// MARK: - Button Style
struct DSButtonStyle: ButtonStyle {
    var variant: Variant = .primary
    var size: Size = .medium
    var isFullWidth: Bool = false
    
    enum Variant {
        case primary
        case secondary
        case tertiary
        case destructive
        case ghost
    }
    
    enum Size {
        case small
        case medium
        case large
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(font)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(backgroundColor(configuration))
            .foregroundColor(foregroundColor(configuration))
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(borderColor, lineWidth: variant == .secondary || variant == .ghost ? 1.5 : 0)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
    
    // MARK: - Style Properties
    
    private var font: Font {
        switch size {
        case .small: return .ds.caption
        case .medium: return .ds.bodyLarge
        case .large: return .ds.headline
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small: return 16
        case .medium: return 24
        case .large: return 32
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small: return 8
        case .medium: return 12
        case .large: return 16
        }
    }
    
    private func backgroundColor(_ configuration: Configuration) -> Color {
        if configuration.isPressed {
            return pressedBackgroundColor
        }
        
        switch variant {
        case .primary:
            return Color.ds.accent
        case .secondary:
            return Color.ds.backgroundSecondary
        case .tertiary:
            return Color.ds.accentLight
        case .destructive:
            return Color.ds.error
        case .ghost:
            return Color.clear
        }
    }
    
    private var pressedBackgroundColor: Color {
        switch variant {
        case .primary:
            return Color.ds.accentDark
        case .secondary:
            return Color.ds.backgroundSecondary.opacity(0.7)
        case .tertiary:
            return Color.ds.accentLight.opacity(0.7)
        case .destructive:
            return Color.ds.error.opacity(0.8)
        case .ghost:
            return Color.gray.opacity(0.1)
        }
    }
    
    private func foregroundColor(_ configuration: Configuration) -> Color {
        switch variant {
        case .primary, .destructive:
            return .white
        case .secondary, .tertiary, .ghost:
            return .ds.textPrimary
        }
    }
    
    private var borderColor: Color {
        switch variant {
        case .secondary:
            return Color.ds.border
        case .ghost:
            return Color.ds.accent
        default:
            return Color.clear
        }
    }
}

// MARK: - Convenience Extensions

extension Button {
    func primaryButton(fullWidth: Bool = false) -> some View {
        self.buttonStyle(DSButtonStyle(variant: .primary, isFullWidth: fullWidth))
    }
    
    func secondaryButton(fullWidth: Bool = false) -> some View {
        self.buttonStyle(DSButtonStyle(variant: .secondary, isFullWidth: fullWidth))
    }
    
    func tertiaryButton() -> some View {
        self.buttonStyle(DSButtonStyle(variant: .tertiary))
    }
    
    func destructiveButton() -> some View {
        self.buttonStyle(DSButtonStyle(variant: .destructive))
    }
    
    func ghostButton() -> some View {
        self.buttonStyle(DSButtonStyle(variant: .ghost))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Button("Primary Button") { }
            .primaryButton()
        
        Button("Secondary Button") { }
            .secondaryButton()
        
        Button("Tertiary Button") { }
            .tertiaryButton()
        
        Button("Destructive") { }
            .destructiveButton()
        
        Button("Ghost Button") { }
            .ghostButton()
        
        Button("Full Width") { }
            .primaryButton(fullWidth: true)
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
