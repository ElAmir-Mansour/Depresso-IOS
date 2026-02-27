// Features/Dashboard/Core/Data/AchievementManager.swift
import Foundation
import SwiftData
import ComposableArchitecture

@MainActor
final class AchievementManager {
    static let shared = AchievementManager()
    
    /// Checks for and unlocks new achievements. Returns a list of newly unlocked achievement types.
    func checkAchievements(userId: String, context: ModelContext) async -> [AchievementType] {
        var newlyUnlocked: [AchievementType] = []
        
        // 1. First Check-in
        let assessmentDescriptor = FetchDescriptor<DailyAssessment>(
            predicate: #Predicate<DailyAssessment> { $0.userId == userId }
        )
        let assessmentCount = (try? context.fetchCount(assessmentDescriptor)) ?? 0
        if assessmentCount >= 1 {
            if unlockAchievement(userId: userId, .firstCheckIn, context: context) {
                newlyUnlocked.append(.firstCheckIn)
            }
        }
        
        // 2. First Journal
        let journalDescriptor = FetchDescriptor<ChatMessage>(
            predicate: #Predicate<ChatMessage> { $0.userId == userId && $0.isFromCurrentUser }
        )
        let journalCount = (try? context.fetchCount(journalDescriptor)) ?? 0
        if journalCount >= 1 {
            if unlockAchievement(userId: userId, .firstJournal, context: context) {
                newlyUnlocked.append(.firstJournal)
            }
        }
        
        // 3. Community Poster
        // Note: For now, CommunityPoster is tracked if they've successfully saved a post.
        // We'd need to query local or backend for this. For simplicity, we check local CommunityPost.
        let postDescriptor = FetchDescriptor<CommunityPost>() // CommunityPost doesn't have userId yet, assuming all local are theirs for now or just generic
        let postCount = (try? context.fetchCount(postDescriptor)) ?? 0
        if postCount >= 1 {
            if unlockAchievement(userId: userId, .communityPoster, context: context) {
                newlyUnlocked.append(.communityPoster)
            }
        }
        
        // 4. 7-Day Streak
        let currentStreak = UserDefaults.standard.integer(forKey: "current_streak")
        if currentStreak >= 7 {
            if unlockAchievement(userId: userId, .sevenDayStreak, context: context) {
                newlyUnlocked.append(.sevenDayStreak)
            }
        }
        
        try? context.save()
        return newlyUnlocked
    }
    
    /// Unlocks an achievement if not already unlocked. Returns true if it was newly unlocked.
    private func unlockAchievement(userId: String, _ type: AchievementType, context: ModelContext) -> Bool {
        let achievementId = type.rawValue
        let uniqueId = "\(userId)_\(achievementId)"
        let predicate = #Predicate<Achievement> { $0.uniqueId == uniqueId }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            if let existing = try context.fetch(descriptor).first {
                if !existing.isUnlocked {
                    existing.isUnlocked = true
                    existing.earnedDate = Date()
                    print("🏆 Unlocked Achievement for \(userId): \(existing.title)")
                    return true
                }
            } else {
                let def = type.definition
                let newAchievement = Achievement(
                    userId: userId,
                    achievementId: achievementId,
                    title: def.title,
                    detail: def.detail,
                    iconName: def.icon,
                    earnedDate: Date(),
                    isUnlocked: true
                )
                context.insert(newAchievement)
                print("🏆 Created and Unlocked Achievement for \(userId): \(newAchievement.title)")
                return true
            }
        } catch {
            print("❌ Error unlocking achievement: \(error)")
        }
        return false
    }
    
    func getAllAchievements(userId: String, context: ModelContext) -> [Achievement] {
        // Initialize all achievement types for this specific user if they don't exist
        for type in AchievementType.allCases {
            let achievementId = type.rawValue
            let uniqueId = "\(userId)_\(achievementId)"
            let predicate = #Predicate<Achievement> { $0.uniqueId == uniqueId }
            let descriptor = FetchDescriptor(predicate: predicate)
            
            if (try? context.fetchCount(descriptor)) == 0 {
                let def = type.definition
                let achievement = Achievement(
                    userId: userId,
                    achievementId: achievementId,
                    title: def.title,
                    detail: def.detail,
                    iconName: def.icon,
                    isUnlocked: false
                )
                context.insert(achievement)
            }
        }
        
        try? context.save()
        
        let predicate = #Predicate<Achievement> { $0.userId == userId }
        var descriptor = FetchDescriptor<Achievement>(predicate: predicate)
        
        let achievements = (try? context.fetch(descriptor)) ?? []
        
        return achievements.sorted { a, b in
            if a.isUnlocked != b.isUnlocked {
                return a.isUnlocked && !b.isUnlocked
            }
            return a.title < b.title
        }
    }
}
