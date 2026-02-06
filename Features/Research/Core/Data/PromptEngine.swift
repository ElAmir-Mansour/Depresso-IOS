// Features/Research/Core/Data/PromptEngine.swift
import Foundation

struct ResearchPrompt: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let category: String
    let emotionFocus: String?
    
    init(id: String, title: String, description: String, category: String, emotionFocus: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.emotionFocus = emotionFocus
    }
}

class PromptEngine {
    static let shared = PromptEngine()
    
    private init() {}
    
    // Pre-defined research prompts
    private let prompts: [ResearchPrompt] = [
        ResearchPrompt(
            id: "morning_mood",
            title: "Morning Check-In",
            description: "How are you feeling this morning? Describe your mood and energy level.",
            category: "Daily Reflection",
            emotionFocus: "general"
        ),
        ResearchPrompt(
            id: "stress_moment",
            title: "Stress Snapshot",
            description: "Think of a stressful moment today. What happened and how did you react?",
            category: "Emotional Awareness",
            emotionFocus: "stress"
        ),
        ResearchPrompt(
            id: "gratitude",
            title: "Three Good Things",
            description: "What are three things you're grateful for today?",
            category: "Positive Psychology",
            emotionFocus: "gratitude"
        ),
        ResearchPrompt(
            id: "cbt_reframe",
            title: "CBT Reframing",
            description: "Identify a negative thought you had today. Can you reframe it in a more balanced way?",
            category: "Cognitive Restructuring",
            emotionFocus: "negative"
        ),
        ResearchPrompt(
            id: "sleep_quality",
            title: "Sleep Reflection",
            description: "How did you sleep last night? What affected your sleep quality?",
            category: "Wellness",
            emotionFocus: "general"
        )
    ]
    
    func getAllPrompts() -> [ResearchPrompt] {
        return prompts
    }
    
    func getPrompt(byId id: String) -> ResearchPrompt? {
        return prompts.first { $0.id == id }
    }
    
    func getDailyPrompt() -> ResearchPrompt {
        // Rotate based on day of year for consistency
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
        let index = dayOfYear % prompts.count
        return prompts[index]
    }
}
