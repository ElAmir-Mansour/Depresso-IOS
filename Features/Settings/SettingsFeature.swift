// Features/Settings/SettingsFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var isPrivacyModeEnabled: Bool = UserDefaults.standard.bool(forKey: "isPrivacyModeEnabled")
        var isModelDownloaded: Bool = false
        var isDownloading: Bool = false
        var downloadProgress: Double = 0.0
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case task
        case togglePrivacyMode(Bool)
        case downloadModel
        case downloadCompleted
        case downloadFailed(Error)
    }
    
    @Dependency(\.aiClient) var aiClient
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .task:
                // Check if model exists
                state.isModelDownloaded = aiClient.isModelAvailable()
                return .none
                
            case .binding(\.isPrivacyModeEnabled):
                let isEnabled = state.isPrivacyModeEnabled
                return .run { send in
                    await send(.togglePrivacyMode(isEnabled))
                }
                
            case .togglePrivacyMode(let isEnabled):
                UserDefaults.standard.set(isEnabled, forKey: "isPrivacyModeEnabled")
                if isEnabled && !state.isModelDownloaded {
                    return .send(.downloadModel)
                }
                return .none
                
            case .downloadModel:
                state.isDownloading = true
                return .run { send in
                    // In a real app, track progress here
                    try await aiClient.downloadModel()
                    await send(.downloadCompleted)
                } catch: { error, send in
                    await send(.downloadFailed(error))
                }
                
            case .downloadCompleted:
                state.isDownloading = false
                state.isModelDownloaded = true
                state.isPrivacyModeEnabled = true // Auto-enable on success
                return .none
                
            case .downloadFailed(let error):
                state.isDownloading = false
                state.isPrivacyModeEnabled = false // Revert
                print("Download failed: \(error)")
                return .none
                
            case .binding:
                return .none
            }
        }
    }
}
