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
        @Presents var profileEdit: ProfileEditFeature.State?
        
        // Profile Info
        var userName: String? = nil
        var userEmail: String? = nil
        var isLinkedToApple: Bool = false
        var isGuest: Bool { !isLinkedToApple }
        
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
        case editProfileButtonTapped
        case profileEdit(PresentationAction<ProfileEditFeature.Action>)
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
                state.isLinkedToApple = UserManager.shared.isLinkedToApple
                
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
                    .run { send in
                        let appleLinks = await MainActor.run { UserManager.shared.$isLinkedToApple.values }
                        for await isLinked in appleLinks {
                            await send(.profileUpdated(name: await MainActor.run { UserManager.shared.userName }, email: await MainActor.run { UserManager.shared.userEmail }))
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
                state.isLinkedToApple = UserManager.shared.isLinkedToApple
                return .none
            
            case .editProfileButtonTapped:
                // Only allow editing if user is linked to Apple (not guest)
                guard !state.isGuest else {
                    state.alert = AlertState {
                        TextState("Link Account Required")
                    } message: {
                        TextState("Please link your account with Apple ID before editing your profile.")
                    }
                    return .none
                }
                
                state.profileEdit = ProfileEditFeature.State(
                    name: state.userName ?? "",
                    email: state.userEmail ?? ""
                )
                return .none
            
            case .profileEdit(.presented(.delegate(.profileSaved))):
                state.profileEdit = nil
                // Refresh profile data
                state.userName = UserManager.shared.userName
                state.userEmail = UserManager.shared.userEmail
                return .none
            
            case .profileEdit(.presented(.delegate(.cancelled))):
                state.profileEdit = nil
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
                        
                        let newToken = try await APIClient.linkAppleAccount(
                            userId: currentUserId,
                            appleUserId: credentials.userId,
                            email: credentials.email,
                            fullName: fullName.isEmpty ? nil : fullName,
                            identityToken: credentials.identityToken
                        )
                        
                        await MainActor.run {
                            UserManager.shared.setSessionToken(newToken, isAppleAuth: true)
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
                state.isLinkedToApple = UserManager.shared.isLinkedToApple
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
                
            case .delegate, .binding, .alert, .profileEdit:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
        .ifLet(\.$profileEdit, action: \.profileEdit) {
            ProfileEditFeature()
        }
    }
}
// Features/Settings/ProfileEditView.swift
import SwiftUI
import ComposableArchitecture

struct ProfileEditView: View {
    @Bindable var store: StoreOf<ProfileEditFeature>
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Your Name", text: $store.name)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .focused($isNameFocused)
                
                TextField("Email (optional)", text: $store.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            } header: {
                Text("Profile Information")
            } footer: {
                Text("This helps personalize your experience")
            }
            
            if let error = store.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.send(.saveButtonTapped)
                }
                .disabled(store.name.trimmingCharacters(in: .whitespaces).isEmpty || store.isSaving)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    store.send(.cancelButtonTapped)
                }
                .disabled(store.isSaving)
            }
        }
        .onAppear {
            isNameFocused = true
        }
    }
}

@Reducer
struct ProfileEditFeature {
    @ObservableState
    struct State: Equatable {
        var name: String = ""
        var email: String = ""
        var isSaving: Bool = false
        var errorMessage: String?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case cancelButtonTapped
        case saveCompleted(Result<Void, Error>)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case profileSaved
            case cancelled
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .saveButtonTapped:
                state.isSaving = true
                state.errorMessage = nil
                
                let trimmedName = state.name.trimmingCharacters(in: .whitespaces)
                let trimmedEmail = state.email.trimmingCharacters(in: .whitespaces)
                
                return .run { send in
                    do {
                        let userId = await MainActor.run { UserManager.shared.userId }
                        guard let userId = userId, !userId.isEmpty else {
                            throw ProfileError.noUserId
                        }
                        
                        // Update backend
                        _ = try await APIClient.updateUserProfile(
                            userId: userId,
                            name: trimmedName,
                            avatarUrl: nil,
                            bio: nil
                        )
                        
                        // Update local
                        await MainActor.run {
                            UserManager.shared.setUserProfile(
                                name: trimmedName,
                                email: trimmedEmail.isEmpty ? nil : trimmedEmail
                            )
                        }
                        
                        await send(.saveCompleted(.success(())))
                    } catch {
                        await send(.saveCompleted(.failure(error)))
                    }
                }
                
            case .saveCompleted(.success):
                state.isSaving = false
                return .send(.delegate(.profileSaved))
                
            case .saveCompleted(.failure(let error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .cancelButtonTapped:
                return .send(.delegate(.cancelled))
                
            case .delegate, .binding:
                return .none
            }
        }
    }
    
    enum ProfileError: Error, LocalizedError {
        case noUserId
        
        var errorDescription: String? {
            "Please sign in first"
        }
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(
            store: Store(initialState: ProfileEditFeature.State(name: "ElAmir")) {
                ProfileEditFeature()
            }
        )
    }
}
