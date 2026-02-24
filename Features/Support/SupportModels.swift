//
//  SupportModels.swift
//  Depresso
//
//  Created by ElAmir Mansour on 24/10/2025.
//

// In Features/Support/SupportModels.swift
import Foundation
import ComposableArchitecture
import SwiftUI

// Represents a helpful article, website, or organization
struct SupportResource: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let description: String
    let url: URL
    let iconName: String // SF Symbol name for visual aid
}

// Represents an emergency contact or helpline
struct Hotline: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let phoneNumber: String
    let description: String? // Optional extra info
    let iconName: String // SF Symbol name
}

// MARK: - Settings Feature

    @Reducer
    struct SettingsFeature {
        @ObservableState
        struct State: Equatable, Sendable {
            // No local settings needed for now
        }
        
        enum Action: BindableAction, Sendable {
            case binding(BindingAction<State>)
            case task
        }
        
        @Dependency(\.aiClient) var aiClient
        
        var body: some Reducer<State, Action> {
            BindingReducer()
            
            Reduce { state, action in
                switch action {
                case .task:
                    return .none
                    
                case .binding:
                    return .none
                }
            }
        }
    }
    
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
