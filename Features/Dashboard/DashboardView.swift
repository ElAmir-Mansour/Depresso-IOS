// In Features/Dashboard/DashboardView.swift
import SwiftUI
import ComposableArchitecture
import Charts
import SwiftData

// MARK: - Layout Constants
private enum Layout {
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 16
    static let compactSpacing: CGFloat = 12
    static let screenPadding: CGFloat = 20
    static let cardPadding: CGFloat = 16
    static let cardCornerRadius: CGFloat = 16
    static let chartHeight: CGFloat = 200
}

struct DashboardView: View {
    @Bindable var store: StoreOf<DashboardFeature>

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack(spacing: Layout.sectionSpacing) {
                        headerGroup
                        actionGroup
                        insightsGroup
                        toolsGroup
                    }
                    .padding(.top, Layout.compactSpacing)
                }
                .background(dashboardBackground)
                .safeAreaInset(edge: .bottom) {
                    Color.clear.frame(height: 80) // Space for custom tab bar
                }
                
                // First-Time User Experience Overlay
                if store.showFirstTimeExperience && !store.hasCompletedFirstCheckin {
                    DSFirstTimeExperience(
                        title: "Take Your First Check-in",
                        message: "Daily check-ins help you track patterns in your mood and wellbeing. It only takes 2 minutes!",
                        actionTitle: "Start Check-in",
                        onAction: {
                            store.send(.takeAssessmentButtonTapped)
                        },
                        onDismiss: {
                            store.send(.dismissFirstTimeExperience)
                        }
                    )
                    .zIndex(1000)
                    .transition(.opacity)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DSSyncIndicator(
                        status: syncIndicatorStatus,
                        lastSyncTime: store.lastSyncTime,
                        onRetry: store.syncStatus == .failed ? { store.send(.retrySyncTapped) } : nil
                    )
                }
            }
            .refreshable {
                await store.send(.refresh).finish()
            }
            .task { await store.send(.task).finish() }
            .sheet(item: $store.scope(state: \.destination?.dailyAssessment, action: \.destination.dailyAssessment)) { assessmentStore in
                 DailyAssessmentView(store: assessmentStore)
            }
            .sheet(item: $store.scope(state: \.destination?.breathing, action: \.destination.breathing)) { breathingStore in
                 BreathingView(store: breathingStore)
            }
            .navigationDestination(for: String.self) { value in
                if value == "achievements" {
                    AchievementsView(achievements: store.achievements)
                }
            }
        }
    }
    
    private var syncIndicatorStatus: DSSyncIndicator.SyncStatus {
        switch store.syncStatus {
        case .synced: return .synced
        case .syncing: return .syncing
        case .failed: return .failed
        case .offline: return .offline
        }
    }
    
    // MARK: - Component Groups
    
    private var headerGroup: some View {
        heroSection
            .padding(.horizontal, Layout.screenPadding)
            .padding(.bottom, 8)
    }
    
    private var actionGroup: some View {
        Group {
            checkInCTASection
                .padding(.horizontal, Layout.screenPadding)
            
            goalsSection
                .padding(.horizontal, Layout.screenPadding)
        }
    }
    
    private var insightsGroup: some View {
        Group {
            if !store.aiInsights.isEmpty {
                AIInsightsCard(insights: store.aiInsights)
                    .padding(.horizontal, Layout.screenPadding)
            }
            
            progressRingsSection
                .padding(.horizontal, Layout.screenPadding)
            
            if let comparison = store.weeklyComparison {
                WeeklyComparisonCard(comparison: comparison)
                    .padding(.horizontal, Layout.screenPadding)
            }
        }
    }
    
    private var toolsGroup: some View {
        Group {
            quickReliefSection
                .padding(.horizontal, Layout.screenPadding)
                
            CBTQuickAccessCard()
                .padding(.horizontal, Layout.screenPadding)
        }
    }
    
    // MARK: - Hero Section
    @ViewBuilder private var heroSection: some View {
        VStack(spacing: 20) {
            // Greeting & Profile
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingText)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(motivationalText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                NavigationLink(value: "achievements") {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.ds.accent.opacity(0.8), Color.ds.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.white)
                                    .font(.system(size: 20))
                            )
                            .shadow(color: Color.ds.accent.opacity(0.3), radius: 8, y: 4)
                        
                        // Badge Notification Dot (if achievements unlocked)
                        if !store.achievements.filter({ $0.isUnlocked }).isEmpty {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().stroke(Color.ds.backgroundPrimary, lineWidth: 2))
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            
            // Streak Banner
            StreakBannerView(
                currentStreak: store.currentStreak,
                longestStreak: store.longestStreak
            )
        }
    }

    // MARK: - Check-in CTA Section
    @ViewBuilder private var checkInCTASection: some View {
        Button {
            DSHaptics.medium()
            store.send(.takeAssessmentButtonTapped)
        } label: {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.canTakeAssessmentToday ? "Daily Check-in" : "Check-in Complete!")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text(store.canTakeAssessmentToday ? "Take 2 minutes to track your mood and unlock personalized insights." : "Great job tracking your mood today. See you tomorrow!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if store.canTakeAssessmentToday {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.white)
                }
            }
            .padding(24)
            .background(
                LinearGradient(
                    colors: store.canTakeAssessmentToday ? 
                        [Color.ds.accent, Color.ds.accent.opacity(0.8)] : 
                        [Color.green.opacity(0.8), Color.green.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: store.canTakeAssessmentToday ? Color.ds.accent.opacity(0.4) : Color.green.opacity(0.3), radius: 15, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!store.canTakeAssessmentToday)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: store.canTakeAssessmentToday)
    }
    
    @ViewBuilder private var quickReliefSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "wind")
                    .font(.title3)
                    .foregroundStyle(Color.ds.accent)
                
                Text("Quick Relief")
                    .font(.system(.title3, design: .rounded).weight(.semibold))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            DashboardCard(title: "Box Breathing") {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calm your nervous system in 2 minutes.")
                            .font(.ds.body)
                            .foregroundStyle(.secondary)
                        
                        Button {
                            store.send(.breathingButtonTapped)
                        } label: {
                            Text("Start Exercise")
                                .font(.ds.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.ds.accent)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.ds.accent.opacity(0.3))
                }
            }
        }
    }
    
    private var goalsSection: some View {
        EnhancedGoalsView(
            store: store.scope(state: \.wellnessTasksState, action: \.wellnessTasks)
        )
    }
    
    private var dashboardBackground: some View {
        LinearGradient(
            colors: [
                Color.ds.backgroundPrimary,
                Color.ds.backgroundSecondary.opacity(0.3)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var motivationalText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Start your day with wellness in mind"
        case 12..<17: return "Keep up the great work today"
        case 17..<22: return "Reflect on your progress today"
        default: return "Rest well for a better tomorrow"
        }
    }
    
    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = store.userName?.split(separator: " ").first.map(String.init) ?? ""
        let suffix = name.isEmpty ? "" : ", \(name)"
        
        switch hour {
        case 5..<12: return "Good Morning\(suffix)"
        case 12..<17: return "Good Afternoon\(suffix)"
        case 17..<22: return "Good Evening\(suffix)"
        default: return "Good Night\(suffix)"
        }
    }

    @ViewBuilder private var progressRingsSection: some View {
        if !store.healthMetrics.isEmpty {
            let steps = store.healthMetrics.first(where: { $0.type == .steps })?.value ?? 0
            let calories = store.healthMetrics.first(where: { $0.type == .calories })?.value ?? 0
            let heartRate = store.healthMetrics.first(where: { $0.type == .heartRate })?.value ?? 0
            
            DashboardCard(title: "Daily Progress") {
                ProgressRingsView(
                    stepsProgress: ProgressGoals.stepsProgress(current: steps),
                    caloriesProgress: ProgressGoals.caloriesProgress(current: calories),
                    heartRateProgress: ProgressGoals.heartRateProgress(current: heartRate),
                    stepsGoal: ProgressGoals.defaultStepsGoal,
                    caloriesGoal: ProgressGoals.defaultCaloriesGoal,
                    heartRateGoal: ProgressGoals.defaultHeartRateGoal,
                    currentSteps: Int(steps),
                    currentCalories: Int(calories),
                    currentHeartRate: Int(heartRate)
                )
                .frame(height: 220)
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - Reusable Dashboard Card
struct DashboardCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.ds.headline)
                .foregroundStyle(.primary)
            
            content
        }
        .padding(Layout.cardPadding)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    let container = try! ModelContainer(for: DailyAssessment.self, WellnessTask.self, Achievement.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    let store = Store(initialState: DashboardFeature.State(isLoading: false)) {
        DashboardFeature()
            .dependency(\.modelContext, try! ModelContextBox(context))
    }
    
    DashboardView(store: store)
        .modelContainer(container)
}
