// Features/Settings/ProfileEditView.swift
import SwiftUI
import ComposableArchitecture

struct ProfileEditView: View {
    @Bindable var store: StoreOf<ProfileEditFeature>
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Avatar Placeholder
                ZStack {
                    Circle()
                        .fill(Color.ds.accent.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.ds.accent)
                    
                    // Edit Badge
                    Circle()
                        .fill(Color.ds.backgroundSecondary)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "pencil")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.ds.accent)
                        )
                        .offset(x: 35, y: 35)
                }
                .padding(.top, 32)
                
                // Input Fields Card
                VStack(spacing: 0) {
                    HStack {
                        Image(systemName: "person.text.rectangle")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField("Your Name", text: $store.name)
                            .textContentType(.name)
                            .autocapitalization(.words)
                            .focused($isNameFocused)
                            .font(.body)
                    }
                    .padding(16)
                    
                    Divider()
                        .padding(.leading, 48)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 24)
                        TextField("Email (optional)", text: $store.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .font(.body)
                    }
                    .padding(16)
                }
                .background(Color.ds.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
                .padding(.horizontal, 20)
                
                Text("Your profile information helps us personalize your journey and connect your data securely.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                if let error = store.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                        Text(error)
                    }
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color.ds.backgroundSecondary.ignoresSafeArea())
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    DSHaptics.buttonPress()
                    store.send(.saveButtonTapped)
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(store.name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.ds.accent)
                }
                .disabled(store.name.trimmingCharacters(in: .whitespaces).isEmpty || store.isSaving)
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") {
                    DSHaptics.light()
                    store.send(.cancelButtonTapped)
                }
                .foregroundStyle(.secondary)
                .disabled(store.isSaving)
            }
        }
        .overlay {
            if store.isSaving {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Saving...")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(32)
                    .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
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
