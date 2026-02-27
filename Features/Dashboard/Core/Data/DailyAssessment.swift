//
//  DailyAssessment.swift
//  Depresso
//
//  Created by ElAmir Mansour on 24/10/2025.
//

// In Core/Data/DailyAssessment.swift
import Foundation
import SwiftData

@Model
final class DailyAssessment {
    var userId: String // Tie to user
    var date: Date // The date the assessment was taken
    var score: Int   // The total PHQ-8 score for that day

    init(userId: String, date: Date = .now, score: Int) {
        self.userId = userId
        // Truncate date to the start of the day to ensure one entry per day
        self.date = Calendar.current.startOfDay(for: date)
        self.score = score
    }
}
