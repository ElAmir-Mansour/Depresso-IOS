// Features/OnBoarding/AuthenticationFeature.swift
import ComposableArchitecture
import Foundation

@Reducer
struct AuthenticationFeature {
    @ObservableState
    struct State: Equatable {
        var isAuthenticating: Bool = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case signInWithAppleButtonTapped
        case signInCompleted(Result<AppleUserCredentials, AuthError>)
        case skipButtonTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case authenticationCompleted(isNewUser: Bool)
            case skipped
        }
    }
    
    struct AuthError: Error, Equatable {
        let message: String
    }

    @Dependency(\.authenticationClient) var authenticationClient

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .signInWithAppleButtonTapped:
                state.isAuthenticating = true
                state.errorMessage = nil
                return .run { send in
                    do {
                        let credentials = try await authenticationClient.signInWithApple()
                        await send(.signInCompleted(.success(credentials)))
                    } catch {
                        await send(.signInCompleted(.failure(AuthError(message: error.localizedDescription))))
                    }
                }

            case .signInCompleted(.success(let credentials)):
                state.isAuthenticating = false
                let fullName = [credentials.fullName?.givenName, credentials.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                let email = credentials.email
                
                return .run { send in
                    do {
                        let result = try await APIClient.appleLogin(
                            appleUserId: credentials.userId,
                            email: email,
                            fullName: fullName.isEmpty ? nil : fullName,
                            identityToken: credentials.identityToken
                        )
                        
                        // Update local user ID, token, and Profile
                        await MainActor.run {
                            UserManager.shared.setUserId(result.userId)
                            UserManager.shared.setSessionToken(result.sessionToken)
                            UserManager.shared.setUserProfile(name: fullName.isEmpty ? nil : fullName, email: email)
                        }
                        
                        await send(.delegate(.authenticationCompleted(isNewUser: result.isNewUser)))
                    } catch {
                        await send(.signInCompleted(.failure(AuthError(message: error.localizedDescription))))
                    }
                }

            case .signInCompleted(.failure(let error)):
                state.isAuthenticating = false
                state.errorMessage = error.message
                return .none

            case .skipButtonTapped:
                return .send(.delegate(.skipped))

            case .delegate:
                return .none
            }
        }
    }
}
