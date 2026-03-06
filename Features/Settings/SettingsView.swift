// Features/Settings/SettingsView.swift
import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader
                
                VStack(spacing: 20) {
                    appearanceSection
                    notificationsSection
                    privacySection
                    dataAccountSection
                }
                .padding(.horizontal, 20)
                
                footerSection
            }
            .padding(.vertical, 24)
        }
        .background(Color.ds.backgroundSecondary.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
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
    
    // MARK: - Components
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.ds.accent.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: store.isGuest ? "person.crop.circle.badge.questionmark" : "person.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.ds.accent)
            }
            
            VStack(spacing: 4) {
                if let name = store.userName {
                    Text(name)
                        .font(.title2.weight(.bold))
                    if let email = store.userEmail {
                        Text(email)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Guest Mode")
                        .font(.title2.weight(.bold))
                    Text("Your data is saved locally.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !store.isGuest {
                Button {
                    store.send(.editProfileButtonTapped)
                } label: {
                    Text("Edit Profile")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.ds.accent)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.ds.accent.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.ds.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
        .padding(.horizontal, 20)
    }
    
    private var appearanceSection: some View {
        SettingsSection(title: "Appearance") {
            SettingsRow(icon: "paintpalette.fill", iconColor: .purple, title: "Theme") {
                Picker("Theme", selection: $store.theme) {
                    ForEach(SettingsFeature.AppTheme.allCases) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.menu)
                .tint(.secondary)
                .onChange(of: store.theme) { _, newTheme in
                    DSHaptics.selection()
                    UserDefaults.standard.set(newTheme.rawValue, forKey: "app_theme")
                }
            }
            
            Divider().padding(.leading, 48)
            
            SettingsRow(icon: "cup.and.saucer.fill", iconColor: .brown, title: "App Style") {
                HStack(spacing: 8) {
                    Text("Future Feature")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Picker("Style", selection: $store.style) {
                        ForEach(AppStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.secondary)
                    .disabled(true)
                }
            }
        }
    }
    
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications") {
            SettingsRow(icon: "bell.badge.fill", iconColor: .red, title: "Daily Reminder") {
                Toggle("", isOn: $store.notificationsEnabled)
                    .labelsHidden()
                    .tint(Color.ds.accent)
                    .onChange(of: store.notificationsEnabled) { _, newValue in
                        DSHaptics.light()
                        store.send(.notificationsToggled(newValue))
                    }
            }
            
            if store.notificationsEnabled {
                Divider().padding(.leading, 48)
                SettingsRow(icon: "clock.fill", iconColor: .blue, title: "Reminder Time") {
                    DatePicker("", selection: $store.dailyReminderTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: store.dailyReminderTime) { _, newValue in
                            DSHaptics.selection()
                            store.send(.reminderTimeChanged(newValue))
                        }
                }
                
                Divider().padding(.leading, 48)
                SettingsRow(icon: "flame.fill", iconColor: .orange, title: "Streak Warnings") {
                    Toggle("", isOn: $store.streakWarningsEnabled)
                        .labelsHidden()
                        .tint(Color.ds.accent)
                        .onChange(of: store.streakWarningsEnabled) { _, newValue in
                            DSHaptics.light()
                            store.send(.streakWarningsToggled(newValue))
                        }
                }
            }
            
            if store.notificationPermissionStatus == .denied {
                Divider().padding(.leading, 48)
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.ds.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications Disabled")
                            .font(.subheadline.weight(.semibold))
                        Text("Enable in Settings app")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Settings") {
                        store.send(.openSystemSettings)
                    }
                    .font(.caption.weight(.bold))
                    .buttonStyle(.borderedProminent)
                    .tint(Color.ds.accent)
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var privacySection: some View {
        SettingsSection(title: "Privacy & AI") {
            SettingsRow(icon: "brain.head.profile", iconColor: .indigo, title: "AI Engine") {
                Text("Google Gemini")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Divider().padding(.leading, 48)
            NavigationLink(destination: ScrollView {
                Text("Your privacy is our priority. We use end-to-end encryption for your journal entries and health data. AI processing is done securely via Google Gemini.")
                    .padding()
            }.navigationTitle("Privacy Policy")) {
                SettingsRow(icon: "lock.shield.fill", iconColor: .green, title: "Privacy Policy") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var dataAccountSection: some View {
        SettingsSection(title: "Account Control") {
            if store.isGuest {
                Button {
                    store.send(.linkAccountButtonTapped)
                } label: {
                    SettingsRow(icon: "apple.logo", iconColor: .primary, title: "Link with Apple") {
                        if store.isLinkingAccount {
                            ProgressView()
                        } else {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(store.isLinkingAccount)
                Divider().padding(.leading, 48)
            }
            
            Button {
                store.send(.logoutButtonTapped)
            } label: {
                SettingsRow(icon: store.isGuest ? "arrow.left.circle.fill" : "rectangle.portrait.and.arrow.right.fill", iconColor: .gray, title: store.isGuest ? "Exit Guest Mode" : "Logout") {
                    EmptyView()
                }
            }
            .buttonStyle(.plain)
            
            Divider().padding(.leading, 48)
            
            Button {
                store.send(.deleteAccountButtonTapped)
            } label: {
                SettingsRow(icon: "trash.fill", iconColor: .red, title: "Delete Account", isDestructive: true) {
                    if store.isDeletingAccount {
                        ProgressView()
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("Version 1.0.0 (Build 1)")
                .font(.caption.weight(.medium))
            Text("Made with ❤️ for mental wellness")
                .font(.caption2)
        }
        .foregroundStyle(.tertiary)
        .padding(.top, 16)
    }
}

// MARK: - Helper Views

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                content
            }
            .background(Color.ds.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
        }
    }
}

struct SettingsRow<TrailingContent: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    var isDestructive: Bool = false
    let trailingContent: TrailingContent
    
    init(icon: String, iconColor: Color, title: String, isDestructive: Bool = false, @ViewBuilder trailingContent: () -> TrailingContent) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.isDestructive = isDestructive
        self.trailingContent = trailingContent()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .font(.body)
                .foregroundStyle(isDestructive ? .red : .primary)
            
            Spacer()
            
            trailingContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
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
