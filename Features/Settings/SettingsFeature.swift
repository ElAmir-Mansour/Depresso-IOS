// Features/Settings/SettingsFeature.swift
import Foundation
import ComposableArchitecture

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        var isDeletingAccount: Bool = false
        var isLinkingAccount: Bool = false
        @Presents var alert: AlertState<Action.Alert>?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case deleteAccountButtonTapped
        case deleteAccountConfirmed
        case deleteAccountCompleted(Result<Void, Error>)
        case linkAccountButtonTapped
        case linkAccountCompleted(Result<Void, Error>)
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)
        
        enum Alert: Equatable {
            case confirmDeletion
        }
        
        enum Delegate: Equatable {
            case accountDeleted
        }
    }
    
    @Dependency(\.aiClient) var aiClient
    @Dependency(\.authenticationClient) var authenticationClient
    
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .linkAccountButtonTapped:
                state.isLinkingAccount = true
                return .run { send in
                    do {
                        let credentials = try await authenticationClient.signInWithApple()
                        let currentUserId = try await UserManager.shared.getCurrentUserId()
                        let fullName = [credentials.fullName?.givenName, credentials.fullName?.familyName]
                            .compactMap { $0 }
                            .joined(separator: " ")
                        
                        try await APIClient.linkAppleAccount(
                            userId: currentUserId,
                            appleUserId: credentials.userId,
                            email: credentials.email,
                            fullName: fullName.isEmpty ? nil : fullName,
                            identityToken: credentials.identityToken
                        )
                        
                        await send(.linkAccountCompleted(.success(())))
                    } catch {
                        await send(.linkAccountCompleted(.failure(error)))
                    }
                }
                
            case .linkAccountCompleted(.success):
                state.isLinkingAccount = false
                state.alert = AlertState { TextState("Success") } message: { TextState("Your account has been successfully linked to Apple ID.") }
                return .none
                
            case .linkAccountCompleted(.failure(let error)):
                state.isLinkingAccount = false
                state.alert = AlertState { TextState("Linking Failed") } message: { TextState(error.localizedDescription) }
                return .none

            case .deleteAccountButtonTapped:
                state.alert = AlertState {
                    TextState("Delete Account")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmDeletion) {
                        TextState("Delete")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("Are you sure? This will permanently delete all your journal entries, metrics, and data. This action cannot be undone.")
                }
                return .none
                
            case .alert(.presented(.confirmDeletion)):
                return .send(.deleteAccountConfirmed)
                
            case .deleteAccountConfirmed:
                state.isDeletingAccount = true
                return .run { send in
                    do {
                        let userId = try await UserManager.shared.getCurrentUserId()
                        try await APIClient.deleteAccount(userId: userId)
                        await send(.deleteAccountCompleted(.success(())))
                    } catch {
                        await send(.deleteAccountCompleted(.failure(error)))
                    }
                }
                
            case .deleteAccountCompleted(.success):
                state.isDeletingAccount = false
                return .send(.delegate(.accountDeleted))
                
            case .deleteAccountCompleted(.failure(let error)):
                state.isDeletingAccount = false
                print("Failed to delete account: \(error)")
                return .none
                
            case .delegate, .binding, .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
