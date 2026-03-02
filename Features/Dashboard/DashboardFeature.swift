// In Features/Dashboard/DashboardFeature.swift
import Foundation
import ComposableArchitecture
import SwiftData
import Charts

@Reducer
struct DashboardFeature {
    @ObservableState
    struct State: Equatable {
        static func == (lhs: DashboardFeature.State, rhs: DashboardFeature.State) -> Bool {
            return lhs.healthMetrics == rhs.healthMetrics &&
                   lhs.weeklySteps == rhs.weeklySteps &&
                   lhs.weeklyEnergy == rhs.weeklyEnergy &&
                   lhs.weeklyHeartRate == rhs.weeklyHeartRate &&
                   lhs.isLoading == rhs.isLoading &&
                   lhs.wellnessTasksState == rhs.wellnessTasksState &&
                   lhs.assessmentHistory.map(\.id) == rhs.assessmentHistory.map(\.id) &&
                   lhs.canTakeAssessmentToday == rhs.canTakeAssessmentToday &&
                   lhs.currentStreak == rhs.currentStreak &&
                   lhs.longestStreak == rhs.longestStreak &&
                   lhs.aiInsights == rhs.aiInsights &&
                   lhs.weeklyComparison?.thisWeekSteps == rhs.weeklyComparison?.thisWeekSteps &&
                   lhs.destination == rhs.destination &&
                   lhs.achievements.map(\.uniqueId) == rhs.achievements.map(\.uniqueId) &&
                   lhs.userName == rhs.userName &&
                   lhs.syncStatus == rhs.syncStatus &&
                   lhs.showFirstTimeExperience == rhs.showFirstTimeExperience
        }

        var healthMetrics: [HealthMetric] = []
        var weeklySteps: [StepData] = []
        var weeklyEnergy: [EnergyData] = []
        var weeklyHeartRate: [HeartRateData] = []
        var isLoading: Bool = true
        var wellnessTasksState = WellnessTasksFeature.State()
        var assessmentHistory: [DailyAssessment] = []
        var canTakeAssessmentToday: Bool = true
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var aiInsights: [HealthInsight] = []
        var weeklyComparison: WeeklyComparison?
        var achievements: [Achievement] = []
        var userName: String? = nil
        var syncStatus: SyncStatus = .synced
        var lastSyncTime: Date? = nil
        var showFirstTimeExperience: Bool = false
        var showNamePrompt: Bool = false
        @Presents var destination: Destination.State?
        
        enum SyncStatus: Equatable {
            case synced
            case syncing
            case failed
            case offline
        }
        
        var hasCompletedFirstCheckin: Bool {
            !assessmentHistory.isEmpty
        }
    }

     enum Action {
         case task
         case refresh
         case healthDataLoaded(Result<([HealthMetric], [StepData], [EnergyData], [HeartRateData]), Error>)
         case wellnessTasks(WellnessTasksFeature.Action)
         case assessmentHistoryLoaded(Result<DailyAssessmentHistory, Error>)
         case streakLoaded(Result<(current: Int, longest: Int), Error>)
         case achievementsLoaded([Achievement])
         case userNameLoaded(String?)
         case takeAssessmentButtonTapped
         case breathingButtonTapped
         case achievementsButtonTapped
         case destination(PresentationAction<Destination.Action>)
         case checkForAssessmentStatus
         case retrySyncTapped
         case dismissFirstTimeExperience
     }
     
     @Reducer(state: .equatable)
     enum Destination {
         case dailyAssessment(DailyAssessmentFeature)
         case breathing(BreathingFeature)
         case achievements
     }
     
     @Dependency(\.healthClient) var healthClient
     @Dependency(\.modelContext) var modelContext
     @Dependency(\.date.now) var now

    @MainActor
    var body: some ReducerOf<Self> {
        Scope(state: \.wellnessTasksState, action: \.wellnessTasks) {
            WellnessTasksFeature()
        }

        Reduce { state, action in
            switch action {
             case .refresh:
                DSHaptics.light()
                state.syncStatus = .syncing
                return .merge(
                    .run { send in
                        try? await healthClient.requestAuthorization()
                        await send(.healthDataLoaded(Result {
                            try await (healthClient.fetchHealthMetrics(), healthClient.fetchWeeklySteps(), healthClient.fetchWeeklyActiveEnergy(), healthClient.fetchWeeklyHeartRate())
                        }))
                    },
                    .run { [modelContext] send in
                        let userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? ""
                        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
                        
                        let history: [DailyAssessment] = (try? await MainActor.run {
                            let predicate = #Predicate<DailyAssessment> { $0.userId == userId && $0.date >= sevenDaysAgo }
                            let descriptor = FetchDescriptor<DailyAssessment>(predicate: predicate, sortBy: [SortDescriptor(\.date)])
                            return try modelContext.context.fetch(descriptor)
                        }) ?? []
                        await send(.assessmentHistoryLoaded(.success(history)))
                        
                        if !userId.isEmpty {
                            let achievements = await AchievementManager.shared.getAllAchievements(userId: userId, context: modelContext.context)
                            await send(.achievementsLoaded(achievements))
                        }
                    }
                )
            
             case .task:
                let shouldLoadHealth = state.healthMetrics.isEmpty
                state.userName = UserManager.shared.userName
                
                // Check if we should show first-time experience
                let hasSeenFTUE = UserDefaults.standard.bool(forKey: "hasSeenFirstTimeExperience")
                
                return .merge(
                    .run { send in
                        let names = await MainActor.run { UserManager.shared.$userName.values }
                        for await name in names {
                            await send(.userNameLoaded(name))
                        }
                    },
                    .run { [modelContext] send in
                        let userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? ""
                        if !userId.isEmpty {
                            let achievements = await AchievementManager.shared.getAllAchievements(userId: userId, context: modelContext.context)
                            await send(.achievementsLoaded(achievements))
                        }
                        
                        if shouldLoadHealth {
                            try? await healthClient.requestAuthorization()
                            await send(.healthDataLoaded(Result {
                                try await (healthClient.fetchHealthMetrics(), healthClient.fetchWeeklySteps(), healthClient.fetchWeeklyActiveEnergy(), healthClient.fetchWeeklyHeartRate())
                            }))
                        }
                    },
                    .run { [modelContext] send in
                        let userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? ""
                        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
                        
                        let history: [DailyAssessment] = (try? await MainActor.run {
                            let predicate = #Predicate<DailyAssessment> { $0.userId == userId && $0.date >= sevenDaysAgo }
                            let descriptor = FetchDescriptor<DailyAssessment>(predicate: predicate, sortBy: [SortDescriptor(\.date)])
                            return try modelContext.context.fetch(descriptor)
                        }) ?? []
                        
                        await send(.assessmentHistoryLoaded(.success(history)))
                    },
                    .send(.checkForAssessmentStatus)
                )

             case .healthDataLoaded(.success(let (metrics, steps, energy, heartRate))):
                 state.healthMetrics = metrics
                 state.weeklySteps = steps
                 state.weeklyEnergy = energy
                 state.weeklyHeartRate = heartRate
                 state.isLoading = false
                 state.syncStatus = .synced
                 state.lastSyncTime = Date()
                 
                 state.aiInsights = InsightGenerator.generateInsights(
                     currentMetrics: metrics,
                     weeklySteps: steps,
                     weeklyEnergy: energy,
                     assessmentHistory: state.assessmentHistory,
                     currentStreak: state.currentStreak
                 )
                 
                 state.weeklyComparison = ComparisonCalculator.calculateWeeklyComparison(
                     weeklySteps: steps,
                     weeklyEnergy: energy,
                     weeklyHeartRate: heartRate,
                     assessmentHistory: state.assessmentHistory
                 )
                 
                 return .none

             case .healthDataLoaded(.failure):
                 state.isLoading = false
                 state.syncStatus = .failed
                 return .none

             case .wellnessTasks:
                 return .none

             case .achievementsLoaded(let achievements):
                 state.achievements = achievements
                 return .none
                 
             case .userNameLoaded(let name):
                 state.userName = name
                 return .none

             case .assessmentHistoryLoaded(.success(let history)):
                  state.assessmentHistory = history
                  
                  // Show FTUE if first time and no assessments
                  let hasSeenFTUE = UserDefaults.standard.bool(forKey: "hasSeenFirstTimeExperience")
                  if !hasSeenFTUE && history.isEmpty {
                      state.showFirstTimeExperience = true
                  }
                  
                  return .run { send in
                      do {
                          let userId = try await MainActor.run { try UserManager.shared.getCurrentUserId() }
                          let streak = try await APIClient.getStreak(userId: userId)
                          UserDefaults.standard.set(streak.current, forKey: "current_streak")
                          await send(.streakLoaded(.success(streak)))
                          await send(.checkForAssessmentStatus)
                      } catch {
                          let current = StreakCalculator.calculateCurrentStreak(from: history)
                          let longest = StreakCalculator.calculateLongestStreak(from: history)
                          UserDefaults.standard.set(current, forKey: "current_streak")
                          await send(.streakLoaded(.success((current, longest))))
                          await send(.checkForAssessmentStatus)
                      }
                  }

             case .assessmentHistoryLoaded(.failure):
                  state.canTakeAssessmentToday = true
                  return .none
            
             case .streakLoaded(.success(let streak)):
                  state.currentStreak = streak.current
                  state.longestStreak = streak.longest
                  
                  state.aiInsights = InsightGenerator.generateInsights(
                      currentMetrics: state.healthMetrics,
                      weeklySteps: state.weeklySteps,
                      weeklyEnergy: state.weeklyEnergy,
                      assessmentHistory: state.assessmentHistory,
                      currentStreak: state.currentStreak
                  )
                  return .none
            
             case .streakLoaded(.failure):
                  return .none

             case .checkForAssessmentStatus:
                  let startOfToday = Calendar.current.startOfDay(for: now)
                  state.canTakeAssessmentToday = !state.assessmentHistory.contains { Calendar.current.isDate($0.date, inSameDayAs: startOfToday) }
                  return .none

             case .takeAssessmentButtonTapped:
                  state.destination = .dailyAssessment(.init())
                  return .none

             case .breathingButtonTapped:
                  state.destination = .breathing(.init())
                  return .none
                  
             case .achievementsButtonTapped:
                  return .none

             case .destination(.presented(.dailyAssessment(.delegate(.assessmentCompleted(let assessment))))):
                  state.destination = nil
                  return .run { [modelContext] send in
                      let userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? ""
                      if !userId.isEmpty {
                          assessment.userId = userId
                      }
                      
                      await MainActor.run {
                          modelContext.context.insert(assessment)
                          try? modelContext.context.save()
                      }
                      
                      do {
                          let streak = try await APIClient.getStreak(userId: userId)
                          UserDefaults.standard.set(streak.current, forKey: "current_streak")
                          await send(.streakLoaded(.success(streak)))
                      } catch {
                          await send(.checkForAssessmentStatus)
                      }
                  }

             case .destination(.dismiss):
                  state.destination = nil
                  return .none

             case .destination:
                  return .none
                  
             case .retrySyncTapped:
                  state.syncStatus = .syncing
                  return .send(.refresh)
                  
             case .dismissFirstTimeExperience:
                  state.showFirstTimeExperience = false
                  UserDefaults.standard.set(true, forKey: "hasSeenFirstTimeExperience")
                  return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

typealias DailyAssessmentHistory = [DailyAssessment]
