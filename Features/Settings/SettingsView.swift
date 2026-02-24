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
        }
        .navigationTitle("Settings")
        .task {
            store.send(.task)
        }
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
