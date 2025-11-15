// StreakBannerView.swift - Improved streak display

import SwiftUI

struct StreakBannerView: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: 16) {
            // Fire icon with animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text("day streak")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if longestStreak > currentStreak {
                    Text("Best: \(longestStreak) days")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Progress indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("Keep going!")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.orange)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.orange)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.05), Color.red.opacity(0.05)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    StreakBannerView(currentStreak: 7, longestStreak: 14)
        .padding()
}
