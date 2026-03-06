// In Features/Support/SupportView.swift
import SwiftUI
import ComposableArchitecture

struct SupportView: View {
    @Bindable var store: StoreOf<SupportFeature>

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Reassuring Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.ds.accent)
                            .padding(.bottom, 8)
                        
                        Text("You are not alone.")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        Text("Help is available right now. We've gathered these trusted resources for whenever you might need them.")
                            .font(.ds.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    
                    // Emergency Hotlines
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Immediate Help")
                            .font(.ds.title3)
                            .padding(.horizontal, 4)
                        
                        ForEach(Array(store.hotlines.enumerated()), id: \.element.id) { index, hotline in
                            // Make the first hotline a "Hero" card
                            if index == 0 {
                                HeroHotlineCard(hotline: hotline)
                            } else {
                                StandardHotlineCard(hotline: hotline)
                            }
                        }
                    }
                    
                    // Resources Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Resources & Information")
                            .font(.ds.title3)
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                        
                        ForEach(store.resources) { resource in
                            ResourceCard(resource: resource)
                        }
                    }
                    
                    // Disclaimer
                    Text("If you are in immediate danger or experiencing a medical emergency, please call your local emergency services (like 911) or go to the nearest emergency room immediately.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.ds.backgroundSecondary.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80) // Tab bar spacing
            }
            .navigationTitle("Support")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.send(.settingsButtonTapped)
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(item: $store.scope(state: \.destination?.settings, action: \.destination.settings)) { settingsStore in
                NavigationStack {
                    SettingsView(store: settingsStore)
                }
            }
        }
    }
}

// MARK: - Components

struct HeroHotlineCard: View {
    let hotline: Hotline
    
    var body: some View {
        Button {
            call(phoneNumber: hotline.phoneNumber)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: hotline.iconName)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "phone.fill")
                        Text("Call Now")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.ds.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white)
                    .clipShape(Capsule())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hotline.name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                    
                    Text(hotline.phoneNumber)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                    
                    if let description = hotline.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.top, 4)
                            .lineLimit(2)
                    }
                }
            }
            .padding(20)
            .background(
                LinearGradient(
                    colors: [Color.ds.accent, Color.ds.accent.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: Color.ds.accent.opacity(0.3), radius: 15, y: 8)
        }
        .buttonStyle(.plain)
    }
    
    private func call(phoneNumber: String) {
        let telephone = "tel://"
        let formattedString = telephone + phoneNumber.filter { $0.isNumber }
        guard let url = URL(string: formattedString) else { return }
        UIApplication.shared.open(url)
    }
}

struct StandardHotlineCard: View {
    let hotline: Hotline
    
    var body: some View {
        Button {
            call(phoneNumber: hotline.phoneNumber)
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.ds.accent.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: hotline.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.ds.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(hotline.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(hotline.phoneNumber)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "phone.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.green)
            }
            .padding(16)
            .background(Color.ds.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private func call(phoneNumber: String) {
        let telephone = "tel://"
        let formattedString = telephone + phoneNumber.filter { $0.isNumber }
        guard let url = URL(string: formattedString) else { return }
        UIApplication.shared.open(url)
    }
}

struct ResourceCard: View {
    let resource: SupportResource
    
    var body: some View {
        Link(destination: resource.url) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(uiColor: .secondarySystemBackground))
                        .frame(width: 48, height: 48)
                    Image(systemName: resource.iconName)
                        .font(.system(size: 20))
                        .foregroundStyle(Color.ds.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(resource.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(resource.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color.ds.backgroundPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SupportView(
        store: Store(initialState: SupportFeature.State()) {
            SupportFeature()
        }
    )
}
