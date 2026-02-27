// Features/Dashboard/AchievementsView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct AchievementsView: View {
    let achievements: [Achievement]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                ForEach(achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
            .padding()
        }
        .background(Color.ds.backgroundPrimary)
        .navigationTitle("Achievements")
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.ds.accent.opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 40))
                    .foregroundStyle(achievement.isUnlocked ? Color.ds.accent.gradient : AnyGradient(Gradient(colors: [.gray])))
                    .opacity(achievement.isUnlocked ? 1.0 : 0.4)
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.green)
                        .background(Circle().fill(.white))
                        .offset(x: 25, y: -25)
                }
            }
            
            VStack(spacing: 4) {
                Text(achievement.title)
                    .font(.ds.headline)
                    .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                
                Text(achievement.detail)
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            
            if let date = achievement.earnedDate {
                Text("Earned \(date, style: .date)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
    }
}

#Preview {
    AchievementsView(achievements: [
        Achievement(userId: "preview", achievementId: "1", title: "Getting Started", detail: "Completed your first check-in.", iconName: "checkmark.seal.fill", earnedDate: Date(), isUnlocked: true),
        Achievement(userId: "preview", achievementId: "2", title: "Week Strong", detail: "Maintained a 7-day streak.", iconName: "flame.fill", isUnlocked: false)
    ])
}
