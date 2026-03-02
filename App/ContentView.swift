// App/ContentView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct ContentView: View {
    @Bindable var store: StoreOf<AppFeature>
    @State private var selectedTab = 0
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            // State Machine for Root Navigation
            switch store.currentFlow {
            case .splash:
                SplashScreenView {
                    store.send(.splashCompleted)
                }
                .transition(.opacity)
                
            case .authentication:
                if let authStore = store.scope(state: \.authState, action: \.auth.presented) {
                    AuthenticationView(store: authStore)
                        .transition(.move(edge: .trailing))
                } else {
                    // Fallback if auth state is nil
                    ProgressView()
                        .onAppear { store.send(.splashCompleted) }
                }
                
            case .welcomeTour:
                WelcomeOnboardingView(
                    onComplete: {
                        store.send(.welcomeTourCompleted)
                    },
                    onSignIn: {
                        // Compatibility link
                        store.send(.welcomeTourCompleted)
                    }
                )
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                
            case .mainApp:
                ZStack {
                    mainContent
                        .fullScreenCover(item: $store.scope(state: \.onboardingState, action: \.onboarding)) { onboardingStore in
                            OnboardingView(store: onboardingStore)
                        }
                    
                    if store.isShowingConfetti {
                        ConfettiView()
                            .transition(.opacity)
                            .zIndex(100)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.default, value: store.currentFlow)
        .task {
            store.send(.task)
        }
        .alert($store.scope(state: \.achievementAlert, action: \.achievementAlert))
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case 0:
                    DashboardView(store: store.scope(state: \.dashboardState, action: \.dashboard))
                        .padding(.bottom, 80)
                case 1:
                    NavigationStack {
                        JournalView(store: store.scope(state: \.journalState, action: \.journal))
                    }
                case 2:
                    CommunityView(store: store.scope(state: \.communityState, action: \.community))
                        .padding(.bottom, 80)
                case 3:
                    InsightsView(store: store.scope(state: \.insightsState, action: \.insights))
                        .padding(.bottom, 80)
                case 4:
                    SupportView(store: store.scope(state: \.supportState, action: \.support))
                        .padding(.bottom, 80)
                default:
                    DashboardView(store: store.scope(state: \.dashboardState, action: \.dashboard))
                        .padding(.bottom, 80)
                }
            }
            .transition(.opacity)
            
            if keyboardHeight == 0 {
                CustomTabBar(selectedTab: $selectedTab)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: keyboardHeight)
        .onAppear {
            setupKeyboardObservers()
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            keyboardHeight = keyboardFrame.height
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
}
