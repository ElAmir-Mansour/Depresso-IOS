import SwiftUI

struct TypingIndicator: View {
    @State private var animatingDot1 = false
    @State private var animatingDot2 = false
    @State private var animatingDot3 = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.ds.accent.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: DSIcons.robot)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.ds.accent)
            }
            
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.ds.accent.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDot1 ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: animatingDot1)
                
                Circle()
                    .fill(Color.ds.accent.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDot2 ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.2), value: animatingDot2)
                
                Circle()
                    .fill(Color.ds.accent.opacity(0.7))
                    .frame(width: 8, height: 8)
                    .scaleEffect(animatingDot3 ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(0.4), value: animatingDot3)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                Capsule()
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .onAppear {
            animatingDot1 = true
            animatingDot2 = true
            animatingDot3 = true
        }
    }
}

#Preview {
    TypingIndicator()
        .padding()
        .background(Color(.systemGroupedBackground))
}
