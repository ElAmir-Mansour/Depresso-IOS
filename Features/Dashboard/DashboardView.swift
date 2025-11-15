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
            ScrollView {
                LazyVStack(spacing: Layout.sectionSpacing) {
                    topSection
                    middleSection
                    chartsSection
                    goalsSection
                }
                .padding(.top, Layout.compactSpacing)
                .padding(.bottom, 100)
            }
            .background(dashboardBackground)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await store.send(.refresh).finish()
            }
            .task { await store.send(.task).finish() }
            .sheet(item: $store.scope(state: \.destination?.dailyAssessment, action: \.destination.dailyAssessment)) { assessmentStore in
                 DailyAssessmentView(store: assessmentStore)
            }
        }
    }
    
    private var topSection: some View {
        Group {
            heroSection
                .padding(.horizontal, Layout.screenPadding)
            
            progressRingsSection
                .padding(.horizontal, Layout.screenPadding)
            
            if !store.aiInsights.isEmpty {
                AIInsightsCard(insights: store.aiInsights)
                    .padding(.horizontal, Layout.screenPadding)
            }
        }
    }
    
    private var middleSection: some View {
        Group {
            healthMetricsSection
                .padding(.horizontal, Layout.screenPadding)
            
            if let comparison = store.weeklyComparison {
                WeeklyComparisonCard(comparison: comparison)
                    .padding(.horizontal, Layout.screenPadding)
            }
            
            dailyAssessmentSection
                .padding(.horizontal, Layout.screenPadding)
        }
    }
    
    private var chartsSection: some View {
        VStack(spacing: Layout.cardSpacing) {
            chartCard(weeklyStepsSection)
            chartCard(weeklyEnergySection)
            chartCard(weeklyHeartRateSection)
        }
        .padding(.horizontal, Layout.screenPadding)
    }
    
    private func chartCard(_ content: some View) -> some View {
        content
            .padding(Layout.cardPadding)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var goalsSection: some View {
        EnhancedGoalsView(
            store: store.scope(state: \.wellnessTasksState, action: \.wellnessTasks)
        )
        .padding(.horizontal, Layout.screenPadding)
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
                
                // Profile/Avatar placeholder
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
            
            // Streak Badge - Full width, more prominent
            StreakBannerView(
                currentStreak: store.currentStreak,
                longestStreak: store.longestStreak
            )
        }
        .padding(Layout.cardPadding)
        .background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius)).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }

    // MARK: - Helper View Builders
    @ViewBuilder private var progressRingsSection: some View {
        if !store.healthMetrics.isEmpty {
            let steps = store.healthMetrics.first(where: { $0.type == .steps })?.value ?? 0
            let calories = store.healthMetrics.first(where: { $0.type == .calories })?.value ?? 0
            let heartRate = store.healthMetrics.first(where: { $0.type == .heartRate })?.value ?? 0
            
            VStack(spacing: 0) {
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
            }
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
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
                  VStack(spacing: 12) {
                      Image(systemName: "heart.text.square")
                          .font(.system(size: 48))
                          .foregroundStyle(.tertiary)
                      
                      Text("No health data yet")
                          .font(.headline)
                          .foregroundStyle(.secondary)
                      
                      Text("Connect to Apple Health to see your vitals")
                          .font(.caption)
                          .foregroundStyle(.tertiary)
                          .multilineTextAlignment(.center)
                  }
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 48)
                  .padding(.horizontal)
                  .background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius)).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
             } else {
                 LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                     ForEach(store.healthMetrics) { metric in
                         EnhancedMetricCard(metric: metric)
                     }
                 }
             }
         }
    }
    @ViewBuilder private var dailyAssessmentSection: some View {
         VStack(alignment: .leading, spacing: 16) {
             HStack {
                 Image(systemName: "chart.line.uptrend.xyaxis")
                     .font(.title3)
                     .foregroundStyle(Color.ds.accent)
                 
                 Text("Mood Tracking")
                     .font(.system(.title3, design: .rounded).weight(.semibold))
                     .foregroundStyle(.primary)
                 
                 Spacer()
                 
                 Button {
                     store.send(.takeAssessmentButtonTapped)
                 } label: {
                     Label("Check-in", systemImage: "plus.circle.fill")
                         .font(.subheadline.weight(.medium))
                 }
                 .buttonStyle(.borderedProminent)
                 .tint(.ds.accent)
                 .disabled(!store.canTakeAssessmentToday)
             }
             
             if store.assessmentHistory.isEmpty && !store.isLoading {
                 VStack(spacing: 12) {
                     Image(systemName: "heart.text.square.fill")
                         .font(.system(size: 48))
                         .foregroundStyle(Color.ds.accent.opacity(0.5))
                     
                     Text("Start tracking your mood")
                         .font(.headline)
                         .foregroundStyle(.primary)
                     
                     Text("Complete your first daily check-in")
                         .font(.subheadline)
                         .foregroundStyle(.secondary)
                 }
                 .frame(maxWidth: .infinity)
                 .padding(.vertical, 48)
                 .background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius)).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
             } else if !store.assessmentHistory.isEmpty {
                 AssessmentChartView(history: store.assessmentHistory)
                     .frame(height: Layout.chartHeight)
                     .padding()
                     .background(Color(UIColor.secondarySystemGroupedBackground)).clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius)).shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
             } else {
                 RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                     .fill(Color(UIColor.systemGray6))
                     .frame(height: Layout.chartHeight)
                     .overlay(ProgressView())
             }
         }
     }
    @ViewBuilder private var weeklyStepsSection: some View {
           VStack(alignment: .leading) {
              Text("Weekly Steps").font(.ds.headline)
              if store.isLoading {
                   RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray6)).frame(height: 150).overlay(ProgressView())
              } else if store.weeklySteps.isEmpty {
                   Text("No step data available.").font(.ds.caption).foregroundStyle(.secondary).padding().frame(maxWidth: .infinity, alignment: .center)
              } else {
                  StepsChartView(stepsData: store.weeklySteps).frame(height: 150)
              }
          }
      }
    @ViewBuilder private var weeklyEnergySection: some View {
        VStack(alignment: .leading) {
            Text("Weekly Active Energy").font(.ds.headline)
            if store.isLoading {
                RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray6)).frame(height: 150).overlay(ProgressView())
            } else if store.weeklyEnergy.isEmpty {
                Text("No energy data available.").font(.ds.caption).foregroundStyle(.secondary).padding().frame(maxWidth: .infinity, alignment: .center)
            } else {
                EnergyChartView(energyData: store.weeklyEnergy).frame(height: 150)
            }
        }
    }

    @ViewBuilder private var weeklyHeartRateSection: some View {
        VStack(alignment: .leading) {
            Text("Weekly Heart Rate").font(.ds.headline)
            if store.isLoading {
                RoundedRectangle(cornerRadius: 8).fill(Color(UIColor.systemGray6)).frame(height: 150).overlay(ProgressView())
            } else if store.weeklyHeartRate.isEmpty {
                Text("No heart rate data available.").font(.ds.caption).foregroundStyle(.secondary).padding().frame(maxWidth: .infinity, alignment: .center)
            } else {
                HeartRateChartView(heartRateData: store.weeklyHeartRate).frame(height: 150)
            }
        }
    }
}

// MARK: - Chart Views
struct StepsChartView: View {
     let stepsData: [StepData] // Defined in HealthClient.swift
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

struct AssessmentChartView: View {
     let history: [DailyAssessment] // Defined in Core/Data
     private var yDomain: ClosedRange<Int> {
          let scores = history.map { $0.score }; let minScore = scores.min() ?? 0; let maxScore = scores.max() ?? 24
          return (minScore > 2 ? minScore - 2 : 0)...(maxScore < 22 ? maxScore + 2 : 24)
     }
     var body: some View {
         Chart(history) { assessment in
             LineMark(x: .value("Date", assessment.date, unit: .day), y: .value("Score", assessment.score)).interpolationMethod(.catmullRom).foregroundStyle(Color.ds.accent)
             PointMark(x: .value("Date", assessment.date, unit: .day), y: .value("Score", assessment.score)).foregroundStyle(Color.ds.accent).symbolSize(CGSize(width: 8, height: 8))
         }
         .chartYScale(domain: yDomain)
         .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.month(.defaultDigits).day(), centered: true) } }
         .chartYAxis { AxisMarks(preset: .automatic, position: .leading) }
     }
 }


// MARK: - Preview (Corrected)
#Preview {
    let container = try! ModelContainer(
        // ✅ Pass individual types correctly, NOT an array literal
        for: WellnessTask.self, DailyAssessment.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let today = Calendar.current.startOfDay(for: .now)
    let sampleHistory = (0..<7).map { index -> DailyAssessment in
        let date = Calendar.current.date(byAdding: .day, value: -index, to: today)!
        return DailyAssessment(date: date, score: Int.random(in: 5...15))
    }.reversed()
    let _ = { sampleHistory.forEach { context.insert($0) } }() // Insert sample data

    let initialState = DashboardFeature.State(
        healthMetrics: HealthMetric.mock, // Assumes defined in HealthMetric.swift
        weeklySteps: StepData.mock, // Assumes defined in HealthClient.swift
        weeklyEnergy: EnergyData.mock,
        weeklyHeartRate: HeartRateData.mock,
        isLoading: false,
        wellnessTasksState: .init(), // Provide default state
        assessmentHistory: Array(sampleHistory)
    )

    let store = Store(initialState: initialState) {
        DashboardFeature()
            .dependency(\.healthClient, .previewValue)
            .dependency(\.modelContext, try! ModelContextBox(context)) // Assumes ModelContextBox exists
    }

    DashboardView(store: store)
        .modelContainer(container) // Keep this modifier
}
