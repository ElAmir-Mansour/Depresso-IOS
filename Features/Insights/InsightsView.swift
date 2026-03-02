// Features/Insights/InsightsView.swift
import SwiftUI
import ComposableArchitecture
import Charts

struct InsightsView: View {
    @Bindable var store: StoreOf<InsightsFeature>
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.large) {
                    if store.isLoading {
                        loadingView
                    } else if let errorMessage = store.errorMessage {
                        errorView(errorMessage)
                    } else {
                        periodSelector
                        insightsContent
                    }
                }
                .padding()
            }
            .background(Color.ds.backgroundPrimary)
            .navigationTitle("Your Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.refresh)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                store.send(.task)
            }
        }
    }
    
    private var periodSelector: some View {
        HStack(spacing: 12) {
            ForEach(InsightsFeature.State.Period.allCases) { period in
                Button {
                    store.send(.selectPeriod(period))
                } label: {
                    Text(period.rawValue)
                        .font(.ds.caption)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(store.selectedPeriod == period ? Color.ds.accent : Color.ds.accent.opacity(0.1))
                        .foregroundColor(store.selectedPeriod == period ? .white : .ds.accent)
                        .clipShape(Capsule())
                }
            }
        }
    }
    
    @ViewBuilder
    private var insightsContent: some View {
        // Show empty state if no data
        if (store.trends?.sentimentTimeline.isEmpty ?? true) && 
           (store.insights?.overview.totalEntries ?? 0) == 0 {
            emptyStateView
        } else {
            if let insights = store.insights {
                overviewCard(insights.overview)
            }
            
            if let trends = store.trends, !trends.sentimentTimeline.isEmpty {
                sentimentChartCard(trends.sentimentTimeline)
            }
            
            if let insights = store.insights, !insights.topDistortions.isEmpty {
                cbtPatternsCard(insights.topDistortions)
            }
            
            if let trends = store.trends, !trends.emotions.isEmpty {
                emotionsCard(trends.emotions)
            }
            
            if let insights = store.insights {
                progressCard(insights.weeklyComparison)
            }
            
            if let communityStats = store.communityStats {
                communityStatsCard(communityStats)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 70))
                .foregroundColor(.ds.accent.opacity(0.6))
                .padding(.top, 40)
            
            Text("Begin Your Journey")
                .font(.title.bold())
            
            Text("Start exploring Depresso to unlock your insights:")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 16) {
                insightFeatureRow(icon: "book.fill", title: "Journal Entries", description: "Track your thoughts and feelings")
                insightFeatureRow(icon: "message.fill", title: "AI Conversations", description: "Chat with your companion")
                insightFeatureRow(icon: "person.3.fill", title: "Community Posts", description: "Share and connect")
            }
            .padding(20)
            .background(Color.ds.accent.opacity(0.05))
            .cornerRadius(16)
            
            Text("Your personalized insights will appear here as you use the app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
    
    private func insightFeatureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.ds.accent)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func overviewCard(_ overview: AnalysisOverviewDTO) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundStyle(.purple)
                    Text("Overview")
                        .font(.ds.headline)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    StatBox(
                        value: "\(overview.totalEntries)",
                        label: "Entries",
                        color: .blue
                    )
                    
                    StatBox(
                        value: String(format: "%.1f%%", overview.avgSentiment * 100),
                        label: "Avg Mood",
                        color: sentimentColor(overview.avgSentiment)
                    )
                    
                    StatBox(
                        value: "\(overview.positiveCount)",
                        label: "Positive",
                        color: .green
                    )
                }
            }
        }
    }
    
    private func sentimentChartCard(_ timeline: [SentimentTimelineDTO]) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundStyle(.blue)
                    Text("Sentiment Journey")
                        .font(.ds.headline)
                    Spacer()
                }
                
                if #available(iOS 16.0, *) {
                    Chart(timeline, id: \.date) { item in
                        LineMark(
                            x: .value("Date", item.date),
                            y: .value("Sentiment", item.avgSentiment)
                        )
                        .foregroundStyle(.blue.gradient)
                        
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Sentiment", item.avgSentiment)
                        )
                        .foregroundStyle(.blue.opacity(0.1).gradient)
                    }
                    .frame(height: 200)
                    .chartYScale(domain: 0...1)
                } else {
                    Text("Chart requires iOS 16+")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func cbtPatternsCard(_ patterns: [CBTPatternFrequencyDTO]) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.purple)
                    Text("CBT Patterns Detected")
                        .font(.ds.headline)
                    Spacer()
                }
                
                ForEach(patterns.indices, id: \.self) { index in
                    let pattern = patterns[index]
                    HStack {
                        Circle()
                            .fill(Color.purple.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(pattern.description ?? "Pattern")
                                .font(.ds.body)
                            Text("Detected \(pattern.frequency) times")
                                .font(.ds.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(pattern.frequency)")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.purple)
                    }
                    
                    if index < patterns.count - 1 {
                        Divider()
                    }
                }
                
                Text("💡 Recognizing these patterns is the first step to changing them!")
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
    }
    
    private func emotionsCard(_ emotions: [EmotionFrequencyDTO]) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "face.smiling")
                        .foregroundStyle(.orange)
                    Text("Emotions")
                        .font(.ds.headline)
                    Spacer()
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(emotions.prefix(6), id: \.emotion) { emotion in
                        HStack {
                            Text(emotionEmoji(emotion.emotion))
                            Text(emotion.emotion.capitalized)
                                .font(.ds.caption)
                            Spacer()
                            Text("\(emotion.count)")
                                .font(.ds.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(Color.ds.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
    
    private func progressCard(_ comparison: WeeklyComparisonAnalysisDTO) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.green)
                    Text("Weekly Progress")
                        .font(.ds.headline)
                    Spacer()
                }
                
                HStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("This Week")
                            .font(.ds.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", comparison.thisWeek * 100))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    
                    Image(systemName: comparison.isImproving ? "arrow.up.right" : "arrow.down.right")
                        .font(.title2)
                        .foregroundStyle(comparison.isImproving ? .green : .red)
                    
                    VStack(spacing: 8) {
                        Text("Last Week")
                            .font(.ds.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", comparison.lastWeek * 100))
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                
                if abs(comparison.improvement) > 1 {
                    Text(comparison.isImproving ? 
                         "🎉 You're \(String(format: "%.1f", abs(comparison.improvement)))% more positive!" :
                         "Your mood dipped \(String(format: "%.1f", abs(comparison.improvement)))% - that's okay, progress isn't always linear")
                        .font(.ds.caption)
                        .foregroundStyle(comparison.isImproving ? .green : .secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }
        }
    }
    
    private func communityStatsCard(_ stats: CommunityStatsDTO) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.pink)
                    Text("Community Impact")
                        .font(.ds.headline)
                    Spacer()
                }
                
                HStack(spacing: 16) {
                    StatBox(
                        value: "\(stats.overview.totalPosts)",
                        label: "Posts",
                        color: .blue
                    )
                    
                    StatBox(
                        value: "\(stats.overview.totalLikes)",
                        label: "Likes",
                        color: .pink
                    )
                    
                    StatBox(
                        value: "\(stats.overview.activeUsers)",
                        label: "Members",
                        color: .purple
                    )
                }
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ForEach(0..<3) { _ in
                DSSkeletonView(height: 200)
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        DSEmptyState(
            icon: "exclamationmark.triangle",
            title: "Couldn't Load Insights",
            message: message,
            actionTitle: "Try Again",
            action: { store.send(.refresh) }
        )
    }
    
    private func sentimentColor(_ score: Double) -> Color {
        if score > 0.7 { return .green }
        if score > 0.4 { return .orange }
        return .red
    }
    
    private func emotionEmoji(_ emotion: String) -> String {
        switch emotion.lowercased() {
        case "anxious": return "😰"
        case "sad": return "😢"
        case "angry": return "😠"
        case "hopeful": return "🌟"
        case "grateful": return "🙏"
        case "calm": return "😌"
        case "motivated": return "💪"
        case "confused": return "😕"
        default: return "😊"
        }
    }
}

struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(color)
            Text(label)
                .font(.ds.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
