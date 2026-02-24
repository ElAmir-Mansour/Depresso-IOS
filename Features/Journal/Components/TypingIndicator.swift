import SwiftUI

struct TypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Consistent AI Avatar
            Circle()
                .fill(Color.ds.accent.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.ds.accent)
                )
            
            HStack(spacing: 4) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.ds.accent.opacity(0.7))
                        .frame(width: 8, height: 8)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1.0 : 0.5)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    TypingIndicator()
        .padding()
        .background(Color.ds.backgroundPrimary)
}
