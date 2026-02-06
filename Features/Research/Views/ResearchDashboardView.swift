import SwiftUI
import ComposableArchitecture

// Simple consent manager stub
class ResearchConsentManager {
    static let shared = ResearchConsentManager()
    var hasConsented: Bool = true
}

struct ResearchDashboardView: View {
    let store: StoreOf<CommunityFeature>
    @State private var showRichInput = false
    @State private var selectedPrompt: ResearchPrompt?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Research Lab")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Contribute to mental health science through your words.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    
                    // Opt-In Status or Call to Action
                    if ResearchConsentManager.shared.hasConsented {
                        ImpactSummaryCard()
                    } else {
                        ResearchOptInCard()
                    }
                    
                    Divider()
                    
                    // Daily Missions (Prompts)
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Missions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(PromptEngine.shared.getAllPrompts()) { prompt in
                            PromptCard(prompt: prompt) {
                                selectedPrompt = prompt
                                showRichInput = true
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { /* Show info */ }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .fullScreenCover(item: $selectedPrompt) { prompt in
                RichInputView(prompt: prompt, store: store)
            }
        }
    }
}

// Subcomponents
struct ImpactSummaryCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.accentColor)
                Text("Your Impact")
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 30) {
                VStack {
                    Text("12")
                        .font(.title2).bold()
                    Text("Entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("Top 5%")
                        .font(.title2).bold()
                    Text("Contributor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("3.5k")
                        .font(.title2).bold()
                    Text("Words")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct ResearchOptInCard: View {
    @State private var showingConsent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Join the Study")
                .font(.headline)
                .foregroundColor(.white)
            Text("Help train AI to understand mental health better. Your data is anonymized and secure.")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            
            Button(action: { showingConsent = true }) {
                Text("Review & Join")
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.accentColor)
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct PromptCard: View {
    let prompt: ResearchPrompt
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(prompt.category.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Text(prompt.description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}
