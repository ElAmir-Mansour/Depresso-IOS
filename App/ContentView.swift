// In App/ContentView.swift

// github testing :D
import SwiftUI
import ComposableArchitecture
import SwiftData

struct ContentView: View {
    let store: StoreOf<AppFeature>
    @State private var selectedTab = 0
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                if viewStore.showingSplash {
                    SplashScreenView {
                        viewStore.send(.splashCompleted)
                    }
                } else if viewStore.showingWelcome {
                    WelcomeOnboardingView {
                        viewStore.send(.welcomeCompleted)
                    }
                } else {
                    mainContent
                        .sheet(store: self.store.scope(state: \.$onboardingState, action: \.onboarding)) { store in
                            OnboardingView(store: store)
                        }
                }
            }
            .task {
                viewStore.send(.task)
            }
        }
    }
    
    private var mainContent: some View {
        ZStack(alignment: .bottom) {
            // Main content switcher
            Group {
                switch selectedTab {
                case 0:
                    DashboardView(store: store.scope(state: \.dashboardState, action: \.dashboard))
                        .padding(.bottom, 80) // Space for tab bar
                case 1:
                    NavigationStack {
                        JournalView(store: store.scope(state: \.journalState, action: \.journal))
                    }
                case 2:
                    CommunityView(store: store.scope(state: \.communityState, action: \.community))
                        .padding(.bottom, 80) // Space for tab bar
                case 3:
                    ResearchDashboardView(store: store.scope(state: \.communityState, action: \.community))
                        .padding(.bottom, 80) // Space for tab bar
                case 4:
                    SupportView(store: store.scope(state: \.supportState, action: \.support))
                        .padding(.bottom, 80) // Space for tab bar
                default:
                    DashboardView(store: store.scope(state: \.dashboardState, action: \.dashboard))
                        .padding(.bottom, 80) // Space for tab bar
                }
            }
            .transition(.opacity)
            
            // Tab bar - hide when keyboard is visible
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

#Preview {
    ContentView(
        store: Store(initialState: AppFeature.State()) {
            AppFeature()
        }
    )
    .modelContainer(for: [ChatMessage.self, WellnessTask.self, CommunityPost.self], inMemory: true)
}
 
