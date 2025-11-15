// Features/Dashboard/Core/Design System/Components/DSEmptyState.swift
import SwiftUI

struct DSEmptyState: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.large) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(Color.ds.accentLight)
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(Color.ds.accent)
            }
            
            // Text Content
            VStack(spacing: DesignSystem.Spacing.small) {
                Text(title)
                    .font(.ds.title3)
                    .foregroundStyle(.primary)
                
                Text(message)
                    .font(.ds.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.large)
            }
            
            // Action Button
            if let actionTitle, let action {
                Button(actionTitle) {
                    DSHaptics.buttonPress()
                    action()
                }
                .primaryButton()
                .padding(.top, DesignSystem.Spacing.small)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(DesignSystem.Spacing.xxxLarge)
        .padding(.bottom, 80) // Space for tab bar
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        DSEmptyState(
            icon: "text.bubble",
            title: "No Stories Yet",
            message: "Be the first to share your journey and inspire others in the community.",
            actionTitle: "Share Story",
            action: { print("Share tapped") }
        )
        
        Divider()
        
        DSEmptyState(
            icon: "heart.text.square",
            title: "No Journal Entries",
            message: "Start your mindfulness journey by writing your first entry."
        )
    }
    .background(Color.ds.backgroundPrimary)
}
