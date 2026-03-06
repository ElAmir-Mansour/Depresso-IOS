//
//  DepressoWidget.swift
//  DepressoWidget
//
//  Created by ElAmir Mansour on 03/03/2026.
//

import WidgetKit
import SwiftUI

// MARK: - Daily Prompt Generator
struct DailyPrompt {
    static func getPrompt(for date: Date) -> String {
        let prompts = [
            "What is one thing you're grateful for today?",
            "How is your body feeling right now?",
            "What's a small win you had today?",
            "What is something you can let go of today?",
            "Who made you smile recently?",
            "Write down one thing you love about yourself.",
            "What is a thought that's been bothering you?",
            "Take a deep breath. What do you notice right now?"
        ]
        let day = Calendar.current.ordinality(of: .dayOfYear, in: .year, for: date) ?? 0
        return prompts[day % prompts.count]
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DepressoEntry {
        DepressoEntry(date: Date(), streak: 5, hasCheckedInToday: false, moodEmoji: "☁️")
    }

    func getSnapshot(in context: Context, completion: @escaping (DepressoEntry) -> ()) {
        let entry = getEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = getEntry()
        
        // Update widget periodically
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getEntry() -> DepressoEntry {
        // Read data from shared App Group
        let sharedDefaults = UserDefaults(suiteName: "group.com.depresso.app")
        let streak = sharedDefaults?.integer(forKey: "currentStreak") ?? 0
        let hasCheckedIn = sharedDefaults?.bool(forKey: "hasCheckedInToday") ?? false
        let moodEmoji = sharedDefaults?.string(forKey: "todayMood") ?? "☁️"
        
        return DepressoEntry(
            date: Date(),
            streak: streak,
            hasCheckedInToday: hasCheckedIn,
            moodEmoji: moodEmoji
        )
    }
}

struct DepressoEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let hasCheckedInToday: Bool
    let moodEmoji: String
}

// MARK: - UI Components
struct WidgetTheme {
    static let gradientStart = Color(red: 0.2, green: 0.15, blue: 0.35)
    static let gradientEnd = Color(red: 0.1, green: 0.08, blue: 0.2)
    static let accent = Color(red: 0.6, green: 0.4, blue: 0.9)
    static let cardBackground = Color.white.opacity(0.1)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    
    static let successGreen = Color(red: 0.3, green: 0.8, blue: 0.5)
    static let warningOrange = Color(red: 0.9, green: 0.6, blue: 0.3)
}

struct GlassmorphicCard<Content: View>: View {
    let padding: CGFloat
    let content: () -> Content
    
    init(padding: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

// MARK: - Widget Views

// Small Widget (2x2)
struct SmallWidgetView: View {
    let entry: DepressoEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(entry.hasCheckedInToday ? WidgetTheme.successGreen.opacity(0.2) : WidgetTheme.warningOrange.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: entry.hasCheckedInToday ? "checkmark" : "bolt.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(entry.hasCheckedInToday ? WidgetTheme.successGreen : WidgetTheme.warningOrange)
                }
                Spacer()
                Text(entry.moodEmoji)
                    .font(.system(size: 24))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.streak)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(WidgetTheme.textPrimary)
                Text(entry.streak == 1 ? "Day Streak" : "Day Streak")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(WidgetTheme.textSecondary)
            }
        }
        .padding()
        // Deep Link: Entire small widget goes to Check-in (Dashboard)
        .widgetURL(URL(string: "depresso://checkin"))
    }
}

// Medium Widget (4x2)
struct MediumWidgetView: View {
    let entry: DepressoEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left Side - Streak & Link to Insights
            Link(destination: URL(string: "depresso://insights")!) {
                VStack(alignment: .leading, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(WidgetTheme.accent.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18))
                            .foregroundColor(WidgetTheme.accent)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(entry.streak)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(WidgetTheme.textPrimary)
                        Text("Day Streak")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(WidgetTheme.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.vertical, 8)
            
            // Right Side - Daily Prompt & Link to Journal
            Link(destination: URL(string: "depresso://journal")!) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Spacer()
                        Image(systemName: "sparkles")
                            .foregroundColor(WidgetTheme.accent)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Daily Reflection")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(WidgetTheme.accent)
                            .textCase(.uppercase)
                        
                        Text(DailyPrompt.getPrompt(for: entry.date))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(WidgetTheme.textPrimary)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
        }
        .padding()
    }
}

// Large Widget (4x4)
struct LargeWidgetView: View {
    let entry: DepressoEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Mindful Journey")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(WidgetTheme.textSecondary)
                Spacer()
                Text(entry.date, style: .date)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(WidgetTheme.textSecondary)
            }
            .padding(.bottom, 4)
            
            // Main Stats
            HStack(spacing: 8) {
                Link(destination: URL(string: "depresso://insights")!) {
                    GlassmorphicCard(padding: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.body)
                            Spacer(minLength: 2)
                            Text("\(entry.streak)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(WidgetTheme.textPrimary)
                            Text("Day Streak")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(WidgetTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                Link(destination: URL(string: "depresso://community")!) {
                    GlassmorphicCard(padding: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Image(systemName: "heart.text.square.fill")
                                .foregroundColor(WidgetTheme.accent)
                                .font(.body)
                            Spacer(minLength: 2)
                            Text(entry.moodEmoji)
                                .font(.system(size: 24))
                            Text("Latest Mood")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(WidgetTheme.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            
            // Daily Prompt
            Link(destination: URL(string: "depresso://journal")!) {
                GlassmorphicCard(padding: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "book.pages.fill")
                                .foregroundColor(WidgetTheme.textSecondary)
                                .font(.system(size: 10))
                            Text("TODAY's PROMPT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(WidgetTheme.textSecondary)
                        }
                        
                        Text(DailyPrompt.getPrompt(for: entry.date))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(WidgetTheme.textPrimary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            // Action Banner
            Link(destination: URL(string: "depresso://checkin")!) {
                GlassmorphicCard(padding: 12) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(entry.hasCheckedInToday ? WidgetTheme.successGreen.opacity(0.2) : WidgetTheme.accent.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: entry.hasCheckedInToday ? "checkmark" : "arrow.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(entry.hasCheckedInToday ? WidgetTheme.successGreen : WidgetTheme.accent)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.hasCheckedInToday ? "All caught up" : "Daily Check-in")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(WidgetTheme.textPrimary)
                            Text(entry.hasCheckedInToday ? "Great job prioritizing yourself." : "Take a moment for your mind.")
                                .font(.system(size: 11))
                                .foregroundColor(WidgetTheme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
    }
}

// MARK: - Widget Configuration

struct DepressoWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                SmallWidgetView(entry: entry)
            }
        }
    }
}

struct DepressoWidget: Widget {
    let kind: String = "DepressoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                DepressoWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        LinearGradient(
                            colors: [WidgetTheme.gradientStart, WidgetTheme.gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
            } else {
                DepressoWidgetEntryView(entry: entry)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [WidgetTheme.gradientStart, WidgetTheme.gradientEnd],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .configurationDisplayName("Depresso Journey")
        .description("Track your streak, check-ins, and daily mood right from your Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    DepressoWidget()
} timeline: {
    DepressoEntry(date: .now, streak: 12, hasCheckedInToday: false, moodEmoji: "☁️")
    DepressoEntry(date: .now, streak: 13, hasCheckedInToday: true, moodEmoji: "✨")
}

#Preview(as: .systemMedium) {
    DepressoWidget()
} timeline: {
    DepressoEntry(date: .now, streak: 12, hasCheckedInToday: false, moodEmoji: "☁️")
    DepressoEntry(date: .now, streak: 13, hasCheckedInToday: true, moodEmoji: "✨")
}

#Preview(as: .systemLarge) {
    DepressoWidget()
} timeline: {
    DepressoEntry(date: .now, streak: 12, hasCheckedInToday: false, moodEmoji: "☁️")
    DepressoEntry(date: .now, streak: 13, hasCheckedInToday: true, moodEmoji: "✨")
}
