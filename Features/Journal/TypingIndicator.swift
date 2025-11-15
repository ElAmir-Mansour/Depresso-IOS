// Features/Journal/TypingIndicator.swift
import SwiftUI

struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            // AI Avatar/Icon
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.ds.accent, Color.purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                )
                .padding(.leading, DesignSystem.Spacing.medium)
            
            // Typing bubble
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationAmount == Double(index) ? 1.2 : 0.8)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animationAmount
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.leading, 8)
            
            Spacer()
        }
        .padding(.vertical, 2)
        .transition(.move(edge: .leading).combined(with: .opacity))
        .onAppear {
            animationAmount = 0
        }
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        TypingIndicator()
        
        Text("Shows when AI is thinking...")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
