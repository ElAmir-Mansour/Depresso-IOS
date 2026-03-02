// App/AppFeature.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        // Feature States
        var journalState = AICompanionJournalFeature.State()
        var dashboardState = DashboardFeature.State()
        var communityState = CommunityFeature.State()
        var insightsState = InsightsFeature.State()
        var supportState = SupportFeature.State()
        var breathingState = BreathingFeature.State()
        
        // Navigation / Flow State
        var currentFlow: AppFlow = .splash
        @Presents var authState: AuthenticationFeature.State?
        @Presents var onboardingState: OnboardingFeature.State?
        
        // Persistent Flags
        var hasCompletedOnboarding: Bool {
            UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        }
        var hasSeenWelcome: Bool {
            UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        }
        
        // Celebration State
        var isShowingConfetti: Bool = false
        @Presents var achievementAlert: AlertState<Action.Alert>?
        
        enum AppFlow: Equatable {
            case splash
            case authentication
            case welcomeTour
            case mainApp
        }
    }

    enum Action {
        case journal(AICompanionJournalFeature.Action)
        case dashboard(DashboardFeature.Action)
        case community(CommunityFeature.Action)
        case insights(InsightsFeature.Action)
        case support(SupportFeature.Action)
        case breathing(BreathingFeature.Action)
        case auth(PresentationAction<AuthenticationFeature.Action>)
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        case task
        case splashCompleted
        case welcomeTourCompleted
        case userRegistrationCompleted(Result<Void, Error>)
        case syncProfile
        case checkAchievements
        case newlyUnlockedAchievements([AchievementType])
        case achievementsRefreshed([Achievement])
        case hideConfetti
        case achievementAlert(PresentationAction<Alert>)
        
        enum Alert: Equatable {}
    }

    @Dependency(\.authenticationClient) var authenticationClient
    @Dependency(\.modelContext) var modelContext
    @Dependency(\.mainQueue) var mainQueue

    @MainActor
    var body: some ReducerOf<Self> {
        Scope(state: \.journalState, action: \.journal) { AICompanionJournalFeature() }
        Scope(state: \.dashboardState, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.communityState, action: \.community) { CommunityFeature() }
        Scope(state: \.insightsState, action: \.insights) { InsightsFeature() }
        Scope(state: \.supportState, action: \.support) { SupportFeature() }
        Scope(state: \.breathingState, action: \.breathing) { BreathingFeature() }

        Reduce { state, action in
            switch action {
            case .task:
                return .send(.syncProfile)
            
            case .splashCompleted:
                let userId = UserDefaults.standard.string(forKey: "depresso_user_id") ?? ""
                
                if userId.isEmpty {
                    state.currentFlow = .authentication
                    state.authState = AuthenticationFeature.State()
                } else if !state.hasSeenWelcome {
                    state.currentFlow = .welcomeTour
                } else if !state.hasCompletedOnboarding {
                    state.currentFlow = .mainApp
                    state.onboardingState = OnboardingFeature.State()
                } else {
                    state.currentFlow = .mainApp
                    return .send(.checkAchievements)
                }
                return .none
                
            case .auth(.presented(.delegate(.authenticationCompleted(let isNewUser)))):
                state.authState = nil
                
                if isNewUser {
                    state.currentFlow = .welcomeTour
                } else {
                    // Returning user: Reset features to ensure fresh data for this user
                    state.dashboardState = DashboardFeature.State()
                    state.journalState = AICompanionJournalFeature.State()
                    state.communityState = CommunityFeature.State()
                    
                    state.currentFlow = .mainApp
                    UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    return .merge(.send(.syncProfile), .send(.checkAchievements))
                }
                return .none
                
            case .auth(.presented(.delegate(.skipped))):
                state.authState = nil
                // Reset features for fresh guest session
                state.dashboardState = DashboardFeature.State()
                state.journalState = AICompanionJournalFeature.State()
                state.communityState = CommunityFeature.State()
                
                // Guest flow: They always see welcome tour then onboarding
                return .run { send in
                    await MainActor.run { UserManager.shared.clearAll() }
                    do {
                        try await UserManager.shared.ensureUserRegistered()
                        await send(.userRegistrationCompleted(.success(())))
                    } catch {
                        await send(.userRegistrationCompleted(.failure(error)))
                    }
                }
                
            case .userRegistrationCompleted(.success):
                state.currentFlow = .welcomeTour
                return .none
                
            case .welcomeTourCompleted:
                UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                state.currentFlow = .mainApp
                if !state.hasCompletedOnboarding {
                    state.onboardingState = OnboardingFeature.State()
                }
                return .none
            
            case .onboarding(.presented(.delegate(.onboardingCompleted))):
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                state.onboardingState = nil
                return .send(.checkAchievements)
                
            case .support(.delegate(.userLoggedOut)):
                // Deep clear session
                UserDefaults.standard.removeObject(forKey: "depresso_user_id")
                UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
                UserDefaults.standard.removeObject(forKey: "hasSeenWelcome")
                Task { @MainActor in UserManager.shared.clearAll() }
                
                state = State() // Reset everything to defaults
                state.currentFlow = .splash
                return .none
                
            case .support(.delegate(.accountDeleted)):
                UserDefaults.standard.removeObject(forKey: "depresso_user_id")
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
                Task { @MainActor in UserManager.shared.clearAll() }
                
                state = State()
                state.currentFlow = .splash
                return .none

            case .syncProfile:
                let userId = UserDefaults.standard.string(forKey: "depresso_user_id") ?? ""
                guard !userId.isEmpty else { return .none }
                return .run { _ in
                    do {
                        let profile = try await APIClient.getUserProfile(userId: userId)
                        await MainActor.run {
                            UserManager.shared.setUserProfile(name: profile.name, email: nil)
                        }
                    } catch {
                        print("⚠️ Profile sync failed (Expected for fresh guests)")
                    }
                }

            case .checkAchievements:
                return .run { [modelContext] send in
                    let userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? ""
                    guard !userId.isEmpty else { return }
                    
                    let newOnes = await AchievementManager.shared.checkAchievements(userId: userId, context: modelContext.context)
                    let all = await AchievementManager.shared.getAllAchievements(userId: userId, context: modelContext.context)
                    
                    if !newOnes.isEmpty { await send(.newlyUnlockedAchievements(newOnes)) }
                    await send(.achievementsRefreshed(all))
                }

            case .newlyUnlockedAchievements(let types):
                state.isShowingConfetti = true
                DSHaptics.success()
                if let first = types.first {
                    let def = first.definition
                    state.achievementAlert = AlertState { TextState("Achievement Unlocked! 🏆") } message: { TextState("You've earned the '\(def.title)' badge: \(def.detail)") }
                }
                return .run { send in
                    try await self.mainQueue.sleep(for: .seconds(5))
                    await send(.hideConfetti)
                }

            case .achievementsRefreshed(let all):
                state.dashboardState.achievements = all
                return .none

            case .hideConfetti:
                state.isShowingConfetti = false
                return .none

            case .journal(.aiMessageSaved(.success)):
                return .send(.checkAchievements)
            case .community(.postSavedSuccessfully):
                return .send(.checkAchievements)
            case .dashboard(.destination(.presented(.dailyAssessment(.delegate(.assessmentCompleted))))):
                return .send(.checkAchievements)

            default:
                return .none
            }
        }
        .ifLet(\.$authState, action: \.auth) { AuthenticationFeature() }
        .ifLet(\.$onboardingState, action: \.onboarding) { OnboardingFeature() }
        .ifLet(\.$achievementAlert, action: \.achievementAlert)
    }
}
