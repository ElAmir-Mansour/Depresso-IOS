// Features/Research/Core/Data/ResearchEntry.swift
import Foundation
import SwiftData

@Model
final class ResearchEntry {
    @Attribute(.unique)
    var id: UUID
    var promptId: String  // Text-based ID
    var content: String
    var sentimentLabel: String  // User-provided sentiment (e.g., "positive", "negative", "neutral")
    var tags: [String]
    var createdAt: Date
    
    // Metadata for research
    var typingSpeed: Double
    var sessionDuration: Double
    var timeOfDay: String
    var deviceModel: String
    
    init(
        id: UUID = UUID(),
        promptId: String,
        content: String,
        sentimentLabel: String,
        tags: [String] = [],
        typingSpeed: Double = 0.0,
        sessionDuration: Double = 0.0,
        timeOfDay: String = "",
        deviceModel: String = ""
    ) {
        self.id = id
        self.promptId = promptId
        self.content = content
        self.sentimentLabel = sentimentLabel
        self.tags = tags
        self.createdAt = .now
        self.typingSpeed = typingSpeed
        self.sessionDuration = sessionDuration
        self.timeOfDay = timeOfDay
        self.deviceModel = deviceModel
    }
}
