// In Core/Data/CommunityPost.swift
import Foundation
import SwiftData
import SwiftUI

@Model
final class CommunityPost {
    @Attribute(.unique)
    var id: UUID
    var userId: String // NEW: Tie to user
    var title: String
    var content: String
    var creationDate: Date
    var category: String
    
    @Attribute(.externalStorage)
    var imageData: Data?
    
    var likeCount: Int = 0

    init(
        id: UUID = UUID(),
        userId: String,
        title: String,
        content: String,
        creationDate: Date = .now,
        category: String = "General",
        imageData: Data? = nil,
        likeCount: Int = 0
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.category = category
        self.imageData = imageData
        self.likeCount = likeCount
    }
}

enum CommunityCategory: String, CaseIterable, Identifiable, Codable {
    case general = "General"
    case anxiety = "Anxiety"
    case depression = "Depression"
    case recovery = "Recovery"
    case dailyWins = "Daily Wins"
    case motivation = "Motivation"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .general: return "message.fill"
        case .anxiety: return "bolt.shield.fill"
        case .depression: return "cloud.rain.fill"
        case .recovery: return "heart.text.square.fill"
        case .dailyWins: return "trophy.fill"
        case .motivation: return "sparkles"
        }
    }
}

struct Comment: Identifiable, Equatable, Codable {
    var id: UUID
    var author: String
    var content: String
    var date: Date
    
    init(id: UUID = UUID(), author: String, content: String, date: Date = .now) {
        self.id = id
        self.author = author
        self.content = content
        self.date = date
    }
}
