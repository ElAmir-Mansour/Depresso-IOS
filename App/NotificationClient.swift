// App/NotificationClient.swift
import Foundation
import UserNotifications
import UIKit
import ComposableArchitecture

@DependencyClient
struct NotificationClient {
    var requestAuthorization: @Sendable () async throws -> Bool = { false }
    var scheduleDailyReminder: @Sendable (Date) async throws -> Void
    var scheduleStreakWarning: @Sendable (Int) async throws -> Void
    var sendAchievementNotification: @Sendable (String, String) async throws -> Void
    var cancelAllNotifications: @Sendable () async -> Void
    var cancelNotification: @Sendable (String) async -> Void
    var getAuthorizationStatus: @Sendable () async -> UNAuthorizationStatus = { .notDetermined }
}

extension NotificationClient: DependencyKey {
    static let liveValue = Self(
        requestAuthorization: {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        },
        
        scheduleDailyReminder: { reminderTime in
            let center = UNUserNotificationCenter.current()
            
            // Cancel existing daily reminder
            center.removePendingNotificationRequests(withIdentifiers: ["daily_checkin"])
            
            // Create content
            let content = UNMutableNotificationContent()
            content.title = "Time for your check-in 📊"
            content.body = "How are you feeling today? Take 2 minutes to track your mood."
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "CHECKIN_REMINDER"
            content.userInfo = ["action": "open_checkin"]
            
            // Create trigger from date
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            
            // Create request
            let request = UNNotificationRequest(
                identifier: "daily_checkin",
                content: content,
                trigger: trigger
            )
            
            try await center.add(request)
        },
        
        scheduleStreakWarning: { currentStreak in
            guard currentStreak >= 3 else { return } // Only warn if streak is meaningful
            
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: ["streak_warning"])
            
            let content = UNMutableNotificationContent()
            content.title = "Don't lose your \(currentStreak)-day streak! 🔥"
            content.body = "You haven't checked in today. Keep your momentum going!"
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "STREAK_WARNING"
            content.userInfo = ["action": "open_checkin"]
            
            // Trigger at 8 PM if user hasn't checked in
            var dateComponents = DateComponents()
            dateComponents.hour = 20
            dateComponents.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "streak_warning",
                content: content,
                trigger: trigger
            )
            
            try await center.add(request)
        },
        
        sendAchievementNotification: { title, message in
            let center = UNUserNotificationCenter.current()
            
            let content = UNMutableNotificationContent()
            content.title = "🏆 Achievement Unlocked!"
            content.body = "\(title): \(message)"
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "ACHIEVEMENT"
            
            // Immediate notification
            let request = UNNotificationRequest(
                identifier: "achievement_\(UUID().uuidString)",
                content: content,
                trigger: nil // Immediate
            )
            
            try await center.add(request)
        },
        
        cancelAllNotifications: {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            center.removeAllDeliveredNotifications()
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        },
        
        cancelNotification: { identifier in
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier])
        },
        
        getAuthorizationStatus: {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            return settings.authorizationStatus
        }
    )
    
    static let testValue = Self(
        requestAuthorization: { true },
        scheduleDailyReminder: { _ in },
        scheduleStreakWarning: { _ in },
        sendAchievementNotification: { _, _ in },
        cancelAllNotifications: { },
        cancelNotification: { _ in },
        getAuthorizationStatus: { .authorized }
    )
}

extension DependencyValues {
    var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}

// MARK: - Notification Categories

extension NotificationClient {
    static func setupNotificationCategories() {
        let checkinAction = UNNotificationAction(
            identifier: "OPEN_CHECKIN",
            title: "Take Check-in",
            options: [.foreground]
        )
        
        let checkinCategory = UNNotificationCategory(
            identifier: "CHECKIN_REMINDER",
            actions: [checkinAction],
            intentIdentifiers: [],
            options: []
        )
        
        let streakAction = UNNotificationAction(
            identifier: "SAVE_STREAK",
            title: "Save My Streak",
            options: [.foreground]
        )
        
        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_WARNING",
            actions: [streakAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            checkinCategory,
            streakCategory
        ])
    }
}
