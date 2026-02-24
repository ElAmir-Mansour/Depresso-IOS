// Features/Dashboard/Core/AI/BackendAIClient.swift
import Foundation
import ComposableArchitecture

// MARK: - 1. Unified Data Models & Interface

// Renamed to avoid conflict with FirebaseAI.ModelContent
struct AIModelContent: Equatable, Sendable {
    let role: String // "user" or "model"
    let parts: [String]
}

@DependencyClient
struct AIClient {
    var generateResponse: @Sendable (_ history: [AIModelContent], _ prompt: String, _ systemPrompt: String?) async throws -> String
}

extension AIClient: DependencyKey {
    static let liveValue: Self = {
        return Self(
            generateResponse: { history, prompt, systemPrompt in
                @Dependency(\.cloudAIClient) var cloudClient
                return try await cloudClient.generateResponse(history, prompt, systemPrompt)
            }
        )
    }()
}

extension DependencyValues {
    var aiClient: AIClient {
        get { self[AIClient.self] }
        set { self[AIClient.self] = newValue }
    }
}

// MARK: - 2. Cloud AI Client (Existing Logic)

struct CloudAIClient {
    var generateResponse: (_ history: [AIModelContent], _ prompt: String, _ systemPrompt: String?) async throws -> String
}

extension CloudAIClient: DependencyKey {
    static let liveValue: Self = {
        let generateResponse: @Sendable (_ history: [AIModelContent], _ prompt: String, _ systemPrompt: String?) async throws -> String = { history, prompt, systemPrompt in
            do {
                try await UserManager.shared.ensureUserRegistered()
                let userId = try await UserManager.shared.getCurrentUserId()
                let entryId = try await getOrCreateJournalEntry(userId: userId)
                let aiMessage = try await APIClient.addMessageToEntry(
                    entryId: entryId,
                    userId: userId,
                    sender: "user",
                    content: prompt
                )
                return aiMessage.content
            } catch {
                print("❌ Backend AI error: \(error)")
                throw error
            }
        }
        return Self(generateResponse: generateResponse)
    }()
    
    private static func getOrCreateJournalEntry(userId: String) async throws -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayKey = "journal_entry_\(dateFormatter.string(from: Date()))"
        if let storedId = UserDefaults.standard.object(forKey: todayKey) as? Int {
            return storedId
        }
        let entry = try await APIClient.createJournalEntry(
            userId: userId,
            title: "Journal - \(dateFormatter.string(from: Date()))",
            content: ""
        )
        UserDefaults.standard.set(entry.id, forKey: todayKey)
        return entry.id
    }
}

extension DependencyValues {
    var cloudAIClient: CloudAIClient {
        get { self[CloudAIClient.self] }
        set { self[CloudAIClient.self] = newValue }
    }
}
