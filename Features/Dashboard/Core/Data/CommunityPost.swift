// In Core/Data/CommunityPost.swift
import Foundation
import SwiftData
import SwiftUI

@Model
final class CommunityPost {
    @Attribute(.unique)
    var id: UUID
    var title: String
    var content: String
    var creationDate: Date
    
    @Attribute(.externalStorage)
    var imageData: Data?
    
    // ✅ ADDED: Property to store like count
    var likeCount: Int = 0

    // Update initializer to accept optional likeCount (defaults to 0)
    init(id: UUID = UUID(), title: String, content: String, creationDate: Date = .now, imageData: Data? = nil, likeCount: Int = 0) {
        self.id = id
        self.title = title
        self.content = content
        self.creationDate = creationDate
        self.imageData = imageData
        self.likeCount = likeCount // Initialize the new property
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
