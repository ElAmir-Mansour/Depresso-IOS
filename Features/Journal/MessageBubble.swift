import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromCurrentUser { 
                Spacer(minLength: 40)
            } else {
                // AI Avatar
                Circle()
                    .fill(Color.ds.accent.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.ds.accent)
                    )
            }

            // MARK: - Text Bubble
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.ds.body) // Use Design System font
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .foregroundStyle(message.isFromCurrentUser ? .white : Color.ds.textPrimary)
                    .background(bubbleBackground)
                    .clipShape(bubbleShape)
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 5,
                        x: 0,
                        y: 2
                    )
                
                HStack(spacing: 4) {
                    Text(message.timestamp, style: .time)
                        .font(.ds.caption2)
                        .foregroundStyle(message.isFromCurrentUser ? .white.opacity(0.7) : .secondary)
                    
                    if !message.isSynced && message.isFromCurrentUser {
                        Image(systemName: "cloud.slash")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isFromCurrentUser ? .trailing : .leading)

            // Removed User Avatar logic for cleaner look
            if !message.isFromCurrentUser { 
                Spacer(minLength: 40) 
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
    
    // Extracted for cleanliness
    private var bubbleBackground: some View {
        Group {
            if message.isFromCurrentUser {
                LinearGradient(
                    colors: [
                        Color.ds.accent,
                        Color.ds.accentDark
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                Color(UIColor.secondarySystemGroupedBackground)
            }
        }
    }
    
    private var bubbleShape: some Shape {
        UnevenRoundedRectangle(
            topLeadingRadius: 20,
            bottomLeadingRadius: message.isFromCurrentUser ? 20 : 4,
            bottomTrailingRadius: message.isFromCurrentUser ? 4 : 20,
            topTrailingRadius: 20
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        MessageBubble(message: ChatMessage(content: "I've been feeling a bit anxious lately and I'm not sure why.", isFromCurrentUser: true))
        MessageBubble(message: ChatMessage(content: "I hear you. Anxiety can be tricky. Can you tell me more about when these feelings started?", isFromCurrentUser: false))
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
