// Features/Settings/SettingsFeature.swift
import Foundation
import ComposableArchitecture
import UserNotifications
import UIKit

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var isDeletingAccount: Bool = false
        var isLinkingAccount: Bool = false
        @Presents var alert: AlertState<Action.Alert>?
        
        // Profile Info
        var userName: String? = nil
        var userEmail: String? = nil
        var isGuest: Bool { userName == nil }
        
        // Preferences
        var theme: AppTheme = .system
        var notificationsEnabled: Bool = true
        var streakWarningsEnabled: Bool = true
        var dailyReminderTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        var notificationPermissionStatus: NotificationPermissionStatus = .notDetermined
        
        enum NotificationPermissionStatus: Equatable {
            case notDetermined
            case authorized
            case denied
        }
    }
    
    enum AppTheme: String, CaseIterable, Identifiable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        var id: String { self.rawValue }
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case task
        case profileUpdated(name: String?, email: String?)
        case logoutButtonTapped
        case deleteAccountButtonTapped
        case deleteAccountConfirmed
        case deleteAccountCompleted(Result<Void, Error>)
        case linkAccountButtonTapped
        case linkAccountCompleted(Result<Void, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        case notificationsToggled(Bool)
        case streakWarningsToggled(Bool)
        case reminderTimeChanged(Date)
        case openSystemSettings
        case notificationPermissionStatusLoaded(UNAuthorizationStatus)
        
        enum Alert: Equatable {
            case confirmDeletion
        }
        
        enum Delegate: Equatable {
            case userLoggedOut
            case accountDeleted
        }
    }
    
    enum SettingsError: Error, LocalizedError {
        case noUserId
        
        var errorDescription: String? {
            "Please sign in to delete your account"
        }
    }
    
    @Dependency(\.aiClient) var aiClient
    @Dependency(\.authenticationClient) var authenticationClient
    @Dependency(\.notificationClient) var notificationClient
    
    @MainActor
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .task:
                // Initial load
                state.userName = UserManager.shared.userName
                state.userEmail = UserManager.shared.userEmail
                
                // Load notification preferences (with default true for first time)
                let preferencesSet = UserDefaults.standard.bool(forKey: "notifications_preference_set")
                if !preferencesSet {
                    state.notificationsEnabled = true
                    state.streakWarningsEnabled = true
                    UserDefaults.standard.set(true, forKey: "notifications_enabled")
                    UserDefaults.standard.set(true, forKey: "streak_warnings_enabled")
                    UserDefaults.standard.set(true, forKey: "notifications_preference_set")
                } else {
                    state.notificationsEnabled = UserDefaults.standard.bool(forKey: "notifications_enabled")
                    state.streakWarningsEnabled = UserDefaults.standard.bool(forKey: "streak_warnings_enabled")
                }
                
                if let savedTime = UserDefaults.standard.object(forKey: "daily_reminder_time") as? Date {
                    state.dailyReminderTime = savedTime
                }
                
                // Observe changes
                return .merge(
                    .run { send in
                        let names = await MainActor.run { UserManager.shared.$userName.values }
                        for await name in names {
                            await send(.profileUpdated(name: name, email: await MainActor.run { UserManager.shared.userEmail }))
                        }
                    },
                    .run { send in
                        let emails = await MainActor.run { UserManager.shared.$userEmail.values }
                        for await email in emails {
                            await send(.profileUpdated(name: await MainActor.run { UserManager.shared.userName }, email: email))
                        }
                    },
                    .run { [notificationClient] send in
                        let status = await notificationClient.getAuthorizationStatus()
                        await send(.notificationPermissionStatusLoaded(status))
                    }
                )
                
            case let .profileUpdated(name, email):
                state.userName = name
                state.userEmail = email
                return .none
                
            case .logoutButtonTapped:
                return .send(.delegate(.userLoggedOut))
                
            case .linkAccountButtonTapped:
                state.isLinkingAccount = true
                return .run { send in
                    do {
                        let credentials = try await authenticationClient.signInWithApple()
                        let currentUserId = await MainActor.run { UserManager.shared.userId }
                        guard let currentUserId = currentUserId, !currentUserId.isEmpty else {
                            throw SettingsError.noUserId
                        }
                        let fullName = [credentials.fullName?.givenName, credentials.fullName?.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        
                        try await APIClient.linkAppleAccount(
                            userId: currentUserId,
                            appleUserId: credentials.userId,
                            email: credentials.email,
                            fullName: fullName.isEmpty ? nil : fullName,
                            identityToken: credentials.identityToken
                        )
                        
                        await MainActor.run {
                            UserManager.shared.setUserProfile(name: fullName.isEmpty ? nil : fullName, email: credentials.email)
                        }
                        
                        await send(.linkAccountCompleted(.success(())))
                    } catch {
                        await send(.linkAccountCompleted(.failure(error)))
                    }
                }
                
            case .linkAccountCompleted(.success):
                state.isLinkingAccount = false
                state.userName = UserManager.shared.userName
                state.userEmail = UserManager.shared.userEmail
                state.alert = AlertState { TextState("Success") } message: { TextState("Your account has been successfully linked to Apple ID.") }
                return .none
                
            case .linkAccountCompleted(.failure(let error)):
                state.isLinkingAccount = false
                state.alert = AlertState { TextState("Linking Failed") } message: { TextState(error.localizedDescription) }
                return .none

            case .deleteAccountButtonTapped:
                state.alert = AlertState {
                    TextState("Delete Account")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("Delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("Are you sure? This will permanently delete all your journal entries, metrics, and data. This action cannot be undone.")
                }
                return .none
                
            case .alert(.presented(.confirmDeletion)):
                return .send(.deleteAccountConfirmed)
                
            case .deleteAccountConfirmed:
                state.isDeletingAccount = true
                return .run { send in
                    do {
                        let userId = await MainActor.run { UserManager.shared.userId }
                        guard let userId = userId, !userId.isEmpty else {
                            throw SettingsError.noUserId
                        }
                        try await APIClient.deleteAccount(userId: userId)
                        await send(.deleteAccountCompleted(.success(())))
                    } catch {
                        await send(.deleteAccountCompleted(.failure(error)))
                    }
                }
                
            case .deleteAccountCompleted(.success):
                state.isDeletingAccount = false
                return .send(.delegate(.accountDeleted))
                
            case .deleteAccountCompleted(.failure(let error)):
                state.isDeletingAccount = false
                state.alert = AlertState {
                    TextState("Delete Failed")
                } message: {
                    TextState(error.localizedDescription)
                }
                print("❌ Failed to delete account: \(error)")
                return .none
                
            case .notificationsToggled(let enabled):
                state.notificationsEnabled = enabled
                UserDefaults.standard.set(enabled, forKey: "notifications_enabled")
                
                return .run { [notificationClient, dailyReminderTime = state.dailyReminderTime] send in
                    if enabled {
                        do {
                            let granted = try await notificationClient.requestAuthorization()
                            if granted {
                                try await notificationClient.scheduleDailyReminder(dailyReminderTime)
                            }
                            let status = await notificationClient.getAuthorizationStatus()
                            await send(.notificationPermissionStatusLoaded(status))
                        } catch {
                            print("Failed to schedule notifications: \(error)")
                        }
                    } else {
                        await notificationClient.cancelAllNotifications()
                    }
                }
                
            case .streakWarningsToggled(let enabled):
                state.streakWarningsEnabled = enabled
                UserDefaults.standard.set(enabled, forKey: "streak_warnings_enabled")
                return .none
                
            case .reminderTimeChanged(let time):
                state.dailyReminderTime = time
                UserDefaults.standard.set(time, forKey: "daily_reminder_time")
                
                if state.notificationsEnabled {
                    return .run { [notificationClient] send in
                        do {
                            try await notificationClient.scheduleDailyReminder(time)
                        } catch {
                            print("Failed to reschedule notification: \(error)")
                        }
                    }
                }
                return .none
                
            case .openSystemSettings:
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Task { @MainActor in
                        UIApplication.shared.open(url)
                    }
                }
                return .none
                
            case .notificationPermissionStatusLoaded(let status):
                state.notificationPermissionStatus = switch status {
                case .authorized, .provisional, .ephemeral: .authorized
                case .denied: .denied
                case .notDetermined: .notDetermined
                @unknown default: .notDetermined
                }
                return .none
                
            case .delegate, .binding, .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
