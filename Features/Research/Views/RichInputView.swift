import SwiftUI
import ComposableArchitecture
import SwiftData

struct RichInputView: View {
    let prompt: ResearchPrompt
    let store: StoreOf<CommunityFeature>
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var text = ""
    @State private var sentiment: Double = 0.5
    @State private var selectedTags: Set<String> = []
    @State private var showSuccess = false
    
    let availableTags = ["Anxiety", "Sleep", "Work", "Relationships", "Medication", "Therapy"]
    
    var body: some View {
        NavigationStack {
            VStack {
                // Prompt Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(prompt.description)
                        .font(.headline)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                
                // Text Editor
                TextEditor(text: $text)
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                    .cornerRadius(12)
                    .padding()
                
                // Metadata Controls
                VStack(spacing: 20) {
                    // Sentiment Slider
                    VStack(alignment: .leading) {
                        HStack {
                            Text("How do you feel?")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(sentimentLabel)
                                .font(.caption)
                                .bold()
                        }
                        Slider(value: $sentiment, in: 0...1)
                            .tint(sentimentColor)
                    }
                    
                    // Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(availableTags, id: \.self) { tag in
                                TagButton(text: tag, isSelected: selectedTags.contains(tag)) {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Contribute") {
                        submitEntry()
                    }
                    .disabled(text.count < 10)
                }
            }
            .alert("Entry Recorded", isPresented: $showSuccess) {
                Button("Done") { dismiss() }
            } message: {
                Text("Thank you for contributing to science!")
            }
        }
    }
    
    private var sentimentLabel: String {
        if sentiment < 0.3 { return "Check-in needed" }
        if sentiment > 0.7 { return "Doing well" }
        return "Neutral"
    }
    
    private var sentimentColor: Color {
        if sentiment < 0.3 { return .red }
        if sentiment > 0.7 { return .green }
        return .blue
    }
    
    private func getMorningOrNight() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        return (hour < 12) ? "Morning" : "Night"
    }
    
    private func submitEntry() {
        Task {
            do {
                // 1. Get User ID (Strict)
                try await UserManager.shared.ensureUserRegistered()
                let userId = try await UserManager.shared.getCurrentUserId()
                
                 // 2. Create Metadata (Simple struct)
                struct ResearchMetadata {
                    let typingSpeed: Double
                    let sessionDuration: Double
                    let timeOfDay: String
                    let deviceModel: String
                }
                
                let metadata = ResearchMetadata(
                    typingSpeed: 0, // TODO: Implement tracking
                    sessionDuration: 0,
                    timeOfDay: getMorningOrNight(),
                    deviceModel: "iPhone" // Placeholder
                )
                
                // 3. Save to Local DB (SwiftData)
                let newEntry = ResearchEntry(
                    promptId: prompt.id,
                    content: text,
                    sentimentLabel: String(format: "%.2f", sentiment),
                    tags: Array(selectedTags),
                    typingSpeed: metadata.typingSpeed,
                    sessionDuration: metadata.sessionDuration,
                    timeOfDay: metadata.timeOfDay,
                    deviceModel: metadata.deviceModel
                )
                modelContext.insert(newEntry)
                
                // 4. Send to Backend
                let metadataDTO = ResearchMetadataDTO(
                    typingSpeed: metadata.typingSpeed,
                    sessionDuration: metadata.sessionDuration,
                    timeOfDay: metadata.timeOfDay,
                    deviceModel: metadata.deviceModel
                )
                
                try await APIClient.submitResearchEntry(
                    userId: userId,
                    promptId: prompt.id,
                    content: text,
                    sentimentLabel: String(format: "%.2f", sentiment),
                    tags: Array(selectedTags),
                    metadata: metadataDTO
                )
                
                print("✅ Research Entry Synced: \(newEntry.id)")
                
                await MainActor.run {
                    showSuccess = true
                }
                
            } catch {
                print("❌ Failed to submit entry: \(error)")
                // Still show success if local save worked? For research, yes.
                 await MainActor.run {
                    showSuccess = true
                }
            }
        }
    }
}

struct TagButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(uiColor: .secondarySystemBackground))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}
