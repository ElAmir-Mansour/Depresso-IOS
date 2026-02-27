// Features/Dashboard/Core/Data/Achievement.swift
import Foundation
import SwiftData

@Model
final class Achievement {
    @Attribute(.unique)
    var uniqueId: String // userId + "_" + achievementId
    var userId: String
    var achievementId: String
    var title: String
    var detail: String
    var iconName: String
    var earnedDate: Date?
    var isUnlocked: Bool
    
    init(userId: String, achievementId: String, title: String, detail: String, iconName: String, earnedDate: Date? = nil, isUnlocked: Bool = false) {
        self.uniqueId = "\(userId)_\(achievementId)"
        self.userId = userId
        self.achievementId = achievementId
        self.title = title
        self.detail = detail
        self.iconName = iconName
        self.earnedDate = earnedDate
        self.isUnlocked = isUnlocked
    }
}

enum AchievementType: String, CaseIterable {
    case firstCheckIn = "first_check_in"
    case sevenDayStreak = "seven_day_streak"
    case firstJournal = "first_journal"
    case communityPoster = "community_poster"
    case breathingMaster = "breathing_master"
    
    var definition: (title: String, detail: String, icon: String) {
        switch self {
        case .firstCheckIn:
            return ("Getting Started", "Completed your first daily check-in.", "checkmark.seal.fill")
        case .sevenDayStreak:
            return ("Week Strong", "Maintained a 7-day wellness streak.", "flame.fill")
        case .firstJournal:
            return ("Dear Diary", "Wrote your first mindful journal entry.", "book.closed.fill")
        case .communityPoster:
            return ("Storyteller", "Shared your first story with the community.", "text.bubble.fill")
        case .breathingMaster:
            return ("Calm Mind", "Completed 10 breathing exercises.", "wind")
        }
    }
}
