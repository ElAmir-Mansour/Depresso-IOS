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
                        vitalsGroup
                        reliefAndGoalsGroup
                    }
                    .padding(.top, Layout.compactSpacing)
                    .padding(.bottom, 100)
                }
                .background(dashboardBackground)
                
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
        Group {
            heroSection
                .padding(.horizontal, Layout.screenPadding)
            
            checkInCTASection
                .padding(.horizontal, Layout.screenPadding)
            
            if !store.aiInsights.isEmpty {
                AIInsightsCard(insights: store.aiInsights)
                    .padding(.horizontal, Layout.screenPadding)
            }
            
            CBTQuickAccessCard()
                .padding(.horizontal, Layout.screenPadding)
        }
    }
    
    private var vitalsGroup: some View {
        Group {
            progressRingsSection
                .padding(.horizontal, Layout.screenPadding)
            
            healthMetricsSection
                .padding(.horizontal, Layout.screenPadding)
            
            if let comparison = store.weeklyComparison {
                WeeklyComparisonCard(comparison: comparison)
                    .padding(.horizontal, Layout.screenPadding)
            }
        }
    }
    
    private var reliefAndGoalsGroup: some View {
        Group {
            chartsSection
            
            quickReliefSection
                .padding(.horizontal, Layout.screenPadding)
            
            goalsSection
                .padding(.horizontal, Layout.screenPadding)
        }
    }
    
    // MARK: - Hero Section
    @ViewBuilder private var heroSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(greetingText)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text(motivationalText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ds.accent, Color.ds.accent.opacity(0.7)],
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
            }
            
            StreakBannerView(
                currentStreak: store.currentStreak,
                longestStreak: store.longestStreak
            )
            
            // Achievements Summary
            NavigationLink(value: "achievements") {
                HStack {
                    HStack(spacing: -8) {
                        ForEach(store.achievements.filter { $0.isUnlocked }.prefix(3)) { achievement in
                            ZStack {
                                Circle()
                                    .fill(Color.ds.accent.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: achievement.iconName)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.ds.accent)
                            }
                            .overlay(Circle().stroke(Color(UIColor.secondarySystemGroupedBackground), lineWidth: 2))
                        }
                        
                        let unlockedCount = store.achievements.filter({ $0.isUnlocked }).count
                        if unlockedCount > 3 {
                            Circle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text("+\(unlockedCount - 3)")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.secondary)
                                )
                                .overlay(Circle().stroke(Color(UIColor.secondarySystemGroupedBackground), lineWidth: 2))
                        }
                    }
                    
                    Text(store.achievements.filter { $0.isUnlocked }.isEmpty ? "Start earning badges" : "Your Achievements")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 8)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.ds.accent.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(Layout.cardPadding)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Check-in CTA Section
    @ViewBuilder private var checkInCTASection: some View {
        Button {
            DSHaptics.medium()
            store.send(.takeAssessmentButtonTapped)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(store.canTakeAssessmentToday ? Color.ds.accent.opacity(0.1) : Color.green.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: store.canTakeAssessmentToday ? "heart.text.square" : "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(store.canTakeAssessmentToday ? Color.ds.accent : Color.green)
                        .symbolEffect(.bounce, value: !store.canTakeAssessmentToday)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(store.canTakeAssessmentToday ? "Ready for your check-in?" : "Check-in Complete!")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(.primary)
                    
                    Text(store.canTakeAssessmentToday ? "Share how you're feeling today" : "Great job tracking your mood today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if store.canTakeAssessmentToday {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(Layout.cardPadding)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                    .stroke(store.canTakeAssessmentToday ? Color.ds.accent.opacity(0.3) : Color.clear, lineWidth: 2)
            )
            .opacity(store.canTakeAssessmentToday ? 1.0 : 0.7)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!store.canTakeAssessmentToday)
        .animation(.spring(response: 0.3), value: store.canTakeAssessmentToday)
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
    
    private var chartsSection: some View {
        VStack(spacing: Layout.cardSpacing) {
            DashboardCard(title: "Weekly Steps") {
                if store.isLoading {
                    ProgressView().frame(height: 150)
                } else if store.weeklySteps.isEmpty {
                    Text("No step data available.").font(.ds.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
                } else {
                    StepsChartView(stepsData: store.weeklySteps).frame(height: 150)
                }
            }
            
            DashboardCard(title: "Weekly Active Energy") {
                if store.isLoading {
                    ProgressView().frame(height: 150)
                } else if store.weeklyEnergy.isEmpty {
                    Text("No energy data available.").font(.ds.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
                } else {
                    EnergyChartView(energyData: store.weeklyEnergy).frame(height: 150)
                }
            }
            
            DashboardCard(title: "Weekly Heart Rate") {
                if store.isLoading {
                    ProgressView().frame(height: 150)
                } else if store.weeklyHeartRate.isEmpty {
                    Text("No heart rate data available.").font(.ds.caption).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .center)
                } else {
                    HeartRateChartView(heartRateData: store.weeklyHeartRate).frame(height: 150)
                }
            }
        }
        .padding(.horizontal, Layout.screenPadding)
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
    
    @ViewBuilder private var healthMetricsSection: some View {
         VStack(alignment: .leading, spacing: 16) {
             HStack {
                 Image(systemName: "heart.text.square.fill")
                     .font(.title3)
                     .foregroundStyle(Color.ds.accent)
                 
                 Text("Today's Vitals")
                     .font(.system(.title3, design: .rounded).weight(.semibold))
                     .foregroundStyle(.primary)
                 
                 Spacer()
             }
             
             if store.isLoading {
                 LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                     DSSkeletonHealthCard()
                     DSSkeletonHealthCard()
                     DSSkeletonHealthCard()
                     DSSkeletonHealthCard()
                 }
             } else if store.healthMetrics.isEmpty {
                  VStack(spacing: 20) {
                      ZStack {
                          Circle()
                              .fill(Color.blue.opacity(0.1))
                              .frame(width: 80, height: 80)
                          Image(systemName: "heart.text.square.fill")
                              .font(.system(size: 40))
                              .foregroundStyle(.blue)
                      }
                      
                      VStack(spacing: 8) {
                          Text("Connect Apple Health")
                              .font(.headline)
                              .foregroundStyle(.primary)
                          
                          Text("We'll analyze your sleep, activity, and heart rate to provide personalized mental health insights.")
                              .font(.subheadline)
                              .foregroundStyle(.secondary)
                              .multilineTextAlignment(.center)
                              .padding(.horizontal, 32)
                      }
                      
                      Button {
                          store.send(.refresh)
                      } label: {
                          Text("Connect Health")
                              .font(.headline)
                              .foregroundColor(.white)
                              .padding(.horizontal, 32)
                              .padding(.vertical, 12)
                              .background(Color.blue)
                              .cornerRadius(12)
                      }
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 40)
                  .background(Color(UIColor.secondarySystemGroupedBackground))
                  .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
                  .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
             } else {
                 LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                     ForEach(store.healthMetrics) { metric in
                         EnhancedMetricCard(metric: metric)
                     }
                 }
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

// MARK: - Chart Views
struct StepsChartView: View {
     let stepsData: [StepData]
     var body: some View {
         Chart(stepsData) { data in BarMark(x: .value("Day", data.date, unit: .day), y: .value("Steps", data.count)).foregroundStyle(Color.ds.accent.gradient) }
         .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true) } }
         .chartYAxis { AxisMarks(position: .leading) }
     }
 }

struct EnergyChartView: View {
    let energyData: [EnergyData]
    var body: some View {
        Chart(energyData) { data in
            LineMark(
                x: .value("Day", data.date, unit: .day),
                y: .value("Energy", data.value)
            )
            .foregroundStyle(Color.green.gradient)
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true) } }
        .chartYAxis { AxisMarks(position: .leading) }
    }
}

struct HeartRateChartView: View {
    let heartRateData: [HeartRateData]
    var body: some View {
        Chart(heartRateData) { data in
            LineMark(
                x: .value("Day", data.date, unit: .day),
                y: .value("Heart Rate", data.value)
            )
            .foregroundStyle(Color.pink.gradient)
            .interpolationMethod(.catmullRom)
        }
        .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true) } }
        .chartYAxis { AxisMarks(position: .leading) }
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
