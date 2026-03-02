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
                        let userId = try await UserManager.shared.getCurrentUserId()
                        
                        async let trends = APIClient.getAnalysisTrends(userId: userId, days: period.days)
                        async let insights = APIClient.getAnalysisInsights(userId: userId)
                        async let communityStats = APIClient.getCommunityStats()
                        
                        return try await (trends, insights, communityStats)
                    }))
                }
                
            case .dataLoaded(.success(let (trends, insights, communityStats))):
                state.trends = trends
                state.insights = insights
                state.communityStats = communityStats
                state.isLoading = false
                return .none
                
            case .dataLoaded(.failure(let error)):
                state.errorMessage = "Failed to load insights: \(error.localizedDescription)"
                state.isLoading = false
                return .none
                
            case .selectPeriod(let period):
                state.selectedPeriod = period
                return .send(.refresh)
            }
        }
    }
}
