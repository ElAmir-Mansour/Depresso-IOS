// Features/Dashboard/CBTQuickAccessCard.swift
import SwiftUI

struct CBTQuickAccessCard: View {
    var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CBT Practice")
                            .font(.ds.headline)
                        Text("Guided journaling exercises")
                            .font(.ds.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                }
                
                HStack(spacing: 12) {
                    CBTButton(
                        icon: "sparkles",
                        title: "Thought\nRecord",
                        color: .purple
                    )
                    
                    CBTButton(
                        icon: "heart.fill",
                        title: "Gratitude\nList",
                        color: .pink
                    )
                    
                    CBTButton(
                        icon: "brain",
                        title: "Mind\nfulness",
                        color: .blue
                    )
                }
                
                Text("💡 Tap Journal tab → ✨ icon to access full CBT exercises")
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
    }
}

struct CBTButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
