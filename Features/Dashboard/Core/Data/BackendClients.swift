
// In Features/Dashboard/Core/Data/BackendClients.swift
import Foundation
import ComposableArchitecture

// MARK: - Backend Models (Prefixed to avoid conflict)

struct BackendJournalEntry: Codable, Equatable, Identifiable, Sendable { let id: Int, user_id: String, title: String?, content: String?, created_at: String }
struct BackendJournalMessage: Codable, Equatable, Identifiable, Sendable { let id: Int, entry_id: Int, user_id: String, sender: String, content: String, created_at: String }

// MARK: - Journal Client

@DependencyClient
struct JournalClient {
    var createEntry: @Sendable (String, String?, String) async throws -> JournalEntryDTO
    var sendMessage: @Sendable (Int, String, String, String) async throws -> AIChatMessageDTO
    var getMessages: @Sendable (Int) async throws -> [AIChatMessageDTO]
}

extension JournalClient: DependencyKey {
    static let liveValue = Self(
        createEntry: { userId, title, content in
            try await APIClient.createJournalEntry(userId: userId, title: title, content: content)
        },
        sendMessage: { entryId, userId, sender, content in
            try await APIClient.addMessageToEntry(entryId: entryId, userId: userId, sender: sender, content: content)
        },
        getMessages: { entryId in
            try await APIClient.getMessages(entryId: entryId)
        }
    )
}

extension DependencyValues {
    var journalClient: JournalClient {
        get { self[JournalClient.self] }
        set { self[JournalClient.self] = newValue }
    }
}
