// Features/Settings/SettingsView.swift
import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    var body: some View {
        Form {
            Section("Privacy & AI") {
                HStack {
                    Text("AI Model")
                    Spacer()
                    Text("Cloud (Google Gemini)")
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("About Research") {
                Text("Depresso uses secure Cloud AI to provide personalized mental health support. Your data is encrypted and safe.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
            Section("Data & Account") {
                Button {
                    store.send(.linkAccountButtonTapped)
                } label: {
                    HStack {
                        if store.isLinkingAccount {
                            ProgressView()
                        } else {
                            Image(systemName: "apple.logo")
                            Text("Link with Apple")
                        }
                    }
                    .foregroundColor(.primary)
                }
                
                Button(role: .destructive) {
                    store.send(.deleteAccountButtonTapped)
                } label: {
                    if store.isDeletingAccount {
                        ProgressView()
                    } else {
                        Text("Delete Account")
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .alert($store.scope(state: \.alert, action: \.alert))
    }
}

#Preview {
    NavigationStack {
        // Mock store for preview
        SettingsView(
            store: Store(initialState: SettingsFeature.State()) {
                SettingsFeature()
            }
        )
    }
}
