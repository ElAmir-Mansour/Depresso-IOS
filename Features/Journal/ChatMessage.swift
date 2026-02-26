// In Features/Journal/ChatMessage.swift
import Foundation
import SwiftData

@Model
final class ChatMessage {
    @Attribute(.unique)
    var id: UUID
    var timestamp: Date
    var content: String
    var isFromCurrentUser: Bool
    var isSynced: Bool

    init(id: UUID = UUID(), timestamp: Date = .now, content: String, isFromCurrentUser: Bool, isSynced: Bool = true) {
        self.id = id
        self.timestamp = timestamp
        self.content = content
        self.isFromCurrentUser = isFromCurrentUser
        self.isSynced = isSynced
    }
}
