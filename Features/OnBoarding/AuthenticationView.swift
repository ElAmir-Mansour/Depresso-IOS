// Features/OnBoarding/AuthenticationView.swift
import SwiftUI
import ComposableArchitecture

struct AuthenticationView: View {
    let store: StoreOf<AuthenticationFeature>
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(
                colors: [Color.ds.accent.opacity(0.1), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo or Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color.ds.accent)
                        .shadow(color: Color.ds.accent.opacity(0.5), radius: 20)
                }
                
                VStack(spacing: 16) {
                    Text("Welcome to Depresso")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Your AI-powered companion for\nmental wellness and understanding.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                VStack(spacing: 20) {
                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Button {
                        store.send(.signInWithAppleButtonTapped)
                    } label: {
                        HStack(spacing: 12) {
                            if store.isAuthenticating {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Image(systemName: "apple.logo")
                                    .font(.title3)
                                Text("Continue with Apple")
                                    .font(.system(size: 20, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    }
                    .disabled(store.isAuthenticating)
                    .padding(.horizontal, 30)
                    
                    Button {
                        store.send(.skipButtonTapped)
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    AuthenticationView(
        store: Store(initialState: AuthenticationFeature.State()) {
            AuthenticationFeature()
        }
    )
}
