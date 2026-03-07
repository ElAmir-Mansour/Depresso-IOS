// Features/Insights/InsightsFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct InsightsFeature {
    @ObservableState
    struct State: Equatable {
        var isLoading = true
        var trends: AnalysisTrendsDTO? = nil
        var insights: AnalysisInsightsDTO? = nil
        var communityStats: CommunityStatsDTO? = nil
        var errorMessage: String? = nil
        var selectedPeriod: Period = .month
        var selectedPattern: CBTPatternFrequencyDTO? = nil
        
        enum Period: String, CaseIterable, Identifiable {
            case week = "7 Days"
            case month = "30 Days"
            case threeMonths = "90 Days"
            
            var id: String { rawValue }
            var days: Int {
                switch self {
                case .week: return 7
                case .month: return 30
                case .threeMonths: return 90
                }
            }
        }
    }
    
    enum Action {
        case task
        case refresh
        case dataLoaded(Result<(AnalysisTrendsDTO, AnalysisInsightsDTO, CommunityStatsDTO), Error>)
        case selectPeriod(State.Period)
        case patternTapped(CBTPatternFrequencyDTO)
        case dismissPattern
    }
    
    enum InsightsError: Error, LocalizedError {
        case noUserId
        
        var errorDescription: String? {
            switch self {
            case .noUserId:
                return "Please sign in to view insights"
            }
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .send(.refresh)
                
            case .refresh:
                state.isLoading = true
                state.errorMessage = nil
                
                return .run { [period = state.selectedPeriod] send in
                    await send(.dataLoaded(Result {
                        let userId = await MainActor.run { UserManager.shared.userId }
                        
                        print("🔍 Insights: Loading data for user: \(userId ?? "nil")")
                        
                        guard let userId = userId, !userId.isEmpty else {
                            throw InsightsError.noUserId
                        }
                        
                        async let trends = APIClient.getAnalysisTrends(userId: userId, days: period.days)
                        async let insights = APIClient.getAnalysisInsights(userId: userId)
                        async let communityStats = APIClient.getCommunityStats()
                        
                        let result = try await (trends, insights, communityStats)
                        print("✅ Insights: Data loaded - \(result.0.sentimentTimeline.count) timeline entries, \(result.1.overview.totalEntries) total entries")
                        return result
                    }))
                }
                
            case .dataLoaded(.success(let (trends, insights, communityStats))):
                print("✅ Insights: Successfully processed data")
                state.trends = trends
                state.insights = insights
                state.communityStats = communityStats
                state.isLoading = false
                return .none
                
            case .dataLoaded(.failure(let error)):
                print("❌ Insights: Failed to load - \(error.localizedDescription)")
                state.errorMessage = "Failed to load insights: \(error.localizedDescription)"
                state.isLoading = false
                return .none
                
            case .selectPeriod(let period):
                state.selectedPeriod = period
                return .send(.refresh)
                
            case .patternTapped(let pattern):
                state.selectedPattern = pattern
                DSHaptics.selection()
                return .none
                
            case .dismissPattern:
                state.selectedPattern = nil
                return .none
            }
        }
    }
}
