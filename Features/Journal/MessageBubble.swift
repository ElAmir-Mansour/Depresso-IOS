import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromCurrentUser { 
                Spacer(minLength: 50)
            } else {
                // AI Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ds.accent.opacity(0.3), Color.ds.accent.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
                    .font(.system(size: 16, design: .rounded))
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .foregroundStyle(message.isFromCurrentUser ? .white : Color.primary)
                    .background(
                        Group {
                            if message.isFromCurrentUser {
                                LinearGradient(
                                    colors: [
                                        Color.ds.accent,
                                        Color.ds.accent.opacity(0.85)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color(UIColor.systemGray6)
                            }
                        }
                    )
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: message.isFromCurrentUser ? 20 : 6,
                            bottomLeadingRadius: 20,
                            bottomTrailingRadius: 20,
                            topTrailingRadius: message.isFromCurrentUser ? 6 : 20
                        )
                    )
                    .shadow(
                        color: message.isFromCurrentUser 
                            ? Color.ds.accent.opacity(0.3) 
                            : .black.opacity(0.05),
                        radius: message.isFromCurrentUser ? 8 : 3,
                        x: 0,
                        y: 2
                    )
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.isFromCurrentUser ? .trailing : .leading)

            if !message.isFromCurrentUser { 
                Spacer(minLength: 50) 
            } else {
                // User Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.blue)
                    )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 8) {
        MessageBubble(message: ChatMessage(content: "User message with gradient background.", isFromCurrentUser: true))
        MessageBubble(message: ChatMessage(content: "AI reply bubble with solid gray color.", isFromCurrentUser: false))
        MessageBubble(message: ChatMessage(content: "Another long message that wraps beautifully and demonstrates consistent padding.", isFromCurrentUser: false))
    }
    .padding()
    .background(Color.ds.backgroundPrimary)
}
