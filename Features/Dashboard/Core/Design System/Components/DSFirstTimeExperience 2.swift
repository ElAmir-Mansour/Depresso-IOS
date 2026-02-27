// Features/Dashboard/Core/Design System/Components/DSFirstTimeExperience.swift
import SwiftUI

struct DSFirstTimeExperience: View {
    let title: String
    let message: String
    let actionTitle: String
    let onAction: () -> Void
    let onDismiss: () -> Void
    
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Card
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.ds.accent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.ds.accent.gradient)
                }
                
                // Content
                VStack(spacing: 12) {
                    Text(title)
                        .font(.ds.title3)
                        .foregroundStyle(Color.ds.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text(message)
                        .font(.ds.body)
                        .foregroundStyle(Color.ds.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // Actions
                VStack(spacing: 12) {
                    Button {
                        dismiss()
                        onAction()
                    } label: {
                        Text(actionTitle)
                            .font(.ds.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.ds.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button {
                        dismiss()
                        onDismiss()
                    } label: {
                        Text("Maybe Later")
                            .font(.ds.body)
                            .foregroundColor(.ds.textSecondary)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 32)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            DSHaptics.success()
        }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            scale = 0.8
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    DSFirstTimeExperience(
        title: "Take Your First Check-in",
        message: "Daily check-ins help you track patterns in your mood and wellbeing. It only takes 2 minutes!",
        actionTitle: "Start Check-in",
        onAction: {},
        onDismiss: {}
    )
}
