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
        case onboarding(PresentationAction<OnboardingFeature.Action>)
        case task
        case splashCompleted
        case welcomeCompleted
        case userRegistrationCompleted(Result<Void, Error>)
    }

    var body: some Reducer<State, Action> {
        Scope(state: \.journalState, action: \.journal) { AICompanionJournalFeature() }
        Scope(state: \.dashboardState, action: \.dashboard) { DashboardFeature() }
        Scope(state: \.communityState, action: \.community) { CommunityFeature() }
        Scope(state: \.supportState, action: \.support) { SupportFeature() }

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

            default:
                return .none
            }
        }
        .ifLet(\.$onboardingState, action: \.onboarding) {
            OnboardingFeature()
        }
    }
}