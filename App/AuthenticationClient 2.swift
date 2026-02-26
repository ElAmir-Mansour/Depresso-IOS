import AuthenticationServices
import ComposableArchitecture
import Foundation

@DependencyClient
struct AuthenticationClient {
    var signInWithApple: () async throws -> AppleUserCredentials
}

struct AppleUserCredentials: Equatable {
    let userId: String
    let email: String?
    let fullName: PersonNameComponents?
    let identityToken: String?
}

extension AuthenticationClient: DependencyKey {
    static let liveValue: Self = {
        return Self(
            signInWithApple: {
                let delegate = await MainActor.run { AppleSignInDelegate() }
                return try await delegate.signIn()
            }
        )
    }()
}

extension DependencyValues {
    var authenticationClient: AuthenticationClient {
        get { self[AuthenticationClient.self] }
        set { self[AuthenticationClient.self] = newValue }
    }
}

// Helper class to handle the delegate callbacks
@MainActor
private class AppleSignInDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<AppleUserCredentials, Error>?
    
    func signIn() async throws -> AppleUserCredentials {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            
            controller.performRequests()
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userId = appleIDCredential.user
            let email = appleIDCredential.email
            let fullName = appleIDCredential.fullName
            let identityToken = appleIDCredential.identityToken.flatMap { String(data: $0, encoding: .utf8) }
            
            let credentials = AppleUserCredentials(
                userId: userId,
                email: email,
                fullName: fullName,
                identityToken: identityToken
            )
            
            resume(with: .success(credentials))
        } else {
            resume(with: .failure(AuthenticationError.unknown))
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        resume(with: .failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            return window
        }
        return UIWindow()
    }
    
    private func resume(with result: Result<AppleUserCredentials, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}

enum AuthenticationError: Error {
    case unknown
}
