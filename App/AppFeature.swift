import SwiftUI
import ComposableArchitecture
import SwiftData

 @Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var journalState = AICompanionJournalFeature.State()
        var dashboardState = DashboardFeature.State()
        var communityState = CommunityFeature.State()
        var supportState = SupportFeature.State()
        var breathingState = BreathingFeature.State()
        @Presents var onboardingState: OnboardingFeature.State?
        var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        var hasSeenWelcome: Bool = UserDefaults.standard.bool(forKey: "hasSeenWelcome")
        var showingSplash: Bool = true
        var showingWelcome: Bool = false
        var isRegisteringUser: Bool = false
    }

    enum Action {
        case journal(AICompanionJournalFeature.Action)
        case dashboard(DashboardFeature.Action)
        case community(CommunityFeature.Action)
        case support(SupportFeature.Action)
        case breathing(BreathingFeature.Action)
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        case task
        case splashCompleted
        case welcomeCompleted
        case userRegistrationCompleted(Result<Void, Error>)
        case signInWelcomeButtonTapped
        case signInWelcomeCompleted(Result<(userId: String, isNewUser: Bool), Error>)
    }

    @Dependency(\.authenticationClient) var authenticationClient

    var body: some Reducer<State, Action> {
        Scope(state: \.journalState, action: \.journal) { AICompanionJournalFeature() }
        Scope(state: \.dashboardState, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.communityState, action: \.community) { CommunityFeature() }
        Scope(state: \.supportState, action: \.support) { SupportFeature() }
        Scope(state: \.breathingState, action: \.breathing) { BreathingFeature() }

        Reduce { state, action in
            switch action {
            case .task:
                state.isRegisteringUser = true
                return .run { send in
                    do {
                        try await UserManager.shared.ensureUserRegistered()
                        await send(.userRegistrationCompleted(.success(())))
                    } catch {
                        await send(.userRegistrationCompleted(.failure(error)))
                    }
                }
            
            case .splashCompleted:
                state.showingSplash = false
                if !state.hasSeenWelcome {
                    state.showingWelcome = true
                }
                return .none
                
            case .welcomeCompleted:
                state.showingWelcome = false
                state.hasSeenWelcome = true
                UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                if !state.hasCompletedOnboarding {
                    state.onboardingState = OnboardingFeature.State()
                }
                return .none
                
            case .signInWelcomeButtonTapped:
                return .run { send in
                    do {
                        let credentials = try await authenticationClient.signInWithApple()
                        let fullName = [credentials.fullName?.givenName, credentials.fullName?.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        
                        let result = try await APIClient.appleLogin(
                            appleUserId: credentials.userId,
                            email: credentials.email,
                            fullName: fullName.isEmpty ? nil : fullName,
                            identityToken: credentials.identityToken
                        )
                        
                        await send(.signInWelcomeCompleted(.success((result.userId, result.isNewUser))))
                    } catch {
                        await send(.signInWelcomeCompleted(.failure(error)))
                    }
                }
                
            case .signInWelcomeCompleted(.success(let (userId, isNewUser))):
                print("✅ Sign in successful. User ID: \(userId), New: \(isNewUser)")
                // Update local user ID
                UserManager.shared.setUserId(userId)
                
                state.showingWelcome = false
                state.hasSeenWelcome = true
                UserDefaults.standard.set(true, forKey: "hasSeenWelcome")
                
                if isNewUser {
                    state.onboardingState = OnboardingFeature.State()
                } else {
                    state.hasCompletedOnboarding = true
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                }
                return .none
                
            case .signInWelcomeCompleted(.failure(let error)):
                print("❌ Sign in failed: \(error)")
                // Optionally show alert
                return .none
            
            case .userRegistrationCompleted(.success):
                state.isRegisteringUser = false
                return .none
                
            case .userRegistrationCompleted(.failure(let error)):
                state.isRegisteringUser = false
                print("❌ User registration failed: \(error)")
                return .none
            
            case .onboarding(.presented(.delegate(.onboardingCompleted))):
                print("✅ Onboarding completed by user")
                state.hasCompletedOnboarding = true
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                state.onboardingState = nil
                return .none
                
            case .support(.delegate(.accountDeleted)):
                print("🔄 Resetting app after account deletion")
                // 1. Clear local data
                UserDefaults.standard.removeObject(forKey: "depresso_user_id")
                UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                UserDefaults.standard.set(false, forKey: "hasSeenWelcome")
                
                // 2. Reset state
                state = State()
                state.showingSplash = true
                state.hasCompletedOnboarding = false
                state.hasSeenWelcome = false
                
                return .none

            default:
                return .none
            }
        }
        .ifLet(\.$onboardingState, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}
