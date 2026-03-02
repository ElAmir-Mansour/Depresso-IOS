// Features/Settings/SettingsView.swift
import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    var body: some View {
        Form {
            Section("Profile") {
                if let name = store.userName {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(name)
                                .font(.headline)
                            if let email = store.userEmail {
                                Text(email)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Image(systemName: "apple.logo")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Guest Mode")
                                .font(.headline)
                            Text("Your data is saved locally and synced anonymously.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "person.crop.circle.badge.questionmark")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Button {
                    store.send(.editProfileButtonTapped)
                } label: {
                    Label("Edit Profile", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    store.send(.logoutButtonTapped)
                } label: {
                    HStack {
                        Image(systemName: store.isGuest ? "arrow.left.circle" : "rectangle.portrait.and.arrow.right")
                        Text(store.isGuest ? "Exit Guest Mode" : "Logout")
                    }
                }
            }
            
            Section("Appearance") {
                Picker("Theme", selection: $store.theme) {
                    ForEach(SettingsFeature.AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section("Notifications") {
                Toggle("Daily Reminder", isOn: $store.notificationsEnabled)
                    .onChange(of: store.notificationsEnabled) { _, newValue in
                        store.send(.notificationsToggled(newValue))
                    }
                
                if store.notificationsEnabled {
                    DatePicker("Reminder Time", selection: $store.dailyReminderTime, displayedComponents: .hourAndMinute)
                        .onChange(of: store.dailyReminderTime) { _, newValue in
                            store.send(.reminderTimeChanged(newValue))
                        }
                    
                    Toggle("Streak Warnings", isOn: $store.streakWarningsEnabled)
                        .onChange(of: store.streakWarningsEnabled) { _, newValue in
                            store.send(.streakWarningsToggled(newValue))
                        }
                }
                
                if store.notificationPermissionStatus == .denied {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.ds.warning)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Notifications Disabled")
                                .font(.caption.weight(.semibold))
                            Text("Enable in Settings app to receive reminders")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Open Settings") {
                            store.send(.openSystemSettings)
                        }
                        .font(.caption2)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section("Privacy & AI") {
                HStack {
                    Text("AI Model")
                    Spacer()
                    Text("Cloud (Google Gemini)")
                        .foregroundStyle(.secondary)
                }
                
                NavigationLink("Privacy Policy") {
                    ScrollView {
                        Text("Your privacy is our priority. We use end-to-end encryption for your journal entries and health data. AI processing is done securely via Google Gemini.")
                            .padding()
                    }
                    .navigationTitle("Privacy Policy")
                }
            }
            
            Section("Data & Account") {
                if store.isGuest {
                    Button {
                        store.send(.linkAccountButtonTapped)
                    } label: {
                        HStack {
                            if store.isLinkingAccount {
                                ProgressView()
                                    .padding(.trailing, 8)
                            } else {
                                Image(systemName: "apple.logo")
                            }
                            Text("Link with Apple")
                        }
                    }
                    .disabled(store.isLinkingAccount)
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
            
            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0 (Build 1)")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("About")
            } footer: {
                Text("Made with ❤️ for mental wellness.")
            }
        }
        .navigationTitle("Settings")
        .task {
            store.send(.task)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .sheet(item: $store.scope(state: \.profileEdit, action: \.profileEdit)) { profileStore in
            NavigationStack {
                ProfileEditView(store: profileStore)
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(
            store: Store(initialState: SettingsFeature.State()) {
                SettingsFeature()
            }
        )
    }
}
