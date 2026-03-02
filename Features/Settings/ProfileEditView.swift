// Features/Settings/ProfileEditView.swift
import SwiftUI
import ComposableArchitecture

struct ProfileEditView: View {
    @Bindable var store: StoreOf<ProfileEditFeature>
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        Form {
            Section {
                TextField("Your Name", text: $store.name)
                    .textContentType(.name)
                    .autocapitalization(.words)
                    .focused($isNameFocused)
                
                TextField("Email (optional)", text: $store.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            } header: {
                Text("Profile Information")
            } footer: {
                Text("This helps personalize your experience")
            }
            
            if let error = store.errorMessage {
                Section {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    store.send(.saveButtonTapped)
                }
                .disabled(store.name.trimmingCharacters(in: .whitespaces).isEmpty || store.isSaving)
            }
            
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    store.send(.cancelButtonTapped)
                }
                .disabled(store.isSaving)
            }
        }
        .onAppear {
            isNameFocused = true
        }
    }
}

@Reducer
struct ProfileEditFeature {
    @ObservableState
    struct State: Equatable {
        var name: String = ""
        var email: String = ""
        var isSaving: Bool = false
        var errorMessage: String?
    }
    
    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case saveButtonTapped
        case cancelButtonTapped
        case saveCompleted(Result<Void, Error>)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case profileSaved
            case cancelled
        }
    }
    
    var body: some ReducerOf<Self> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .saveButtonTapped:
                state.isSaving = true
                state.errorMessage = nil
                
                let trimmedName = state.name.trimmingCharacters(in: .whitespaces)
                let trimmedEmail = state.email.trimmingCharacters(in: .whitespaces)
                
                return .run { send in
                    do {
                        let userId = await MainActor.run { UserManager.shared.userId }
                        guard let userId = userId, !userId.isEmpty else {
                            throw ProfileError.noUserId
                        }
                        
                        // Update backend
                        _ = try await APIClient.updateUserProfile(
                            userId: userId,
                            name: trimmedName,
                            avatarUrl: nil,
                            bio: nil
                        )
                        
                        // Update local
                        await MainActor.run {
                            UserManager.shared.setUserProfile(
                                name: trimmedName,
                                email: trimmedEmail.isEmpty ? nil : trimmedEmail
                            )
                        }
                        
                        await send(.saveCompleted(.success(())))
                    } catch {
                        await send(.saveCompleted(.failure(error)))
                    }
                }
                
            case .saveCompleted(.success):
                state.isSaving = false
                return .send(.delegate(.profileSaved))
                
            case .saveCompleted(.failure(let error)):
                state.isSaving = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .cancelButtonTapped:
                return .send(.delegate(.cancelled))
                
            case .delegate, .binding:
                return .none
            }
        }
    }
    
    enum ProfileError: Error, LocalizedError {
        case noUserId
        
        var errorDescription: String? {
            "Please sign in first"
        }
    }
}

#Preview {
    NavigationStack {
        ProfileEditView(
            store: Store(initialState: ProfileEditFeature.State(name: "ElAmir")) {
                ProfileEditFeature()
            }
        )
    }
}
