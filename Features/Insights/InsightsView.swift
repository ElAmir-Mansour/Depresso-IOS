// Features/Insights/InsightsView.swift
import SwiftUI
import ComposableArchitecture
import Charts

struct InsightsView: View {
    @Bindable var store: StoreOf<InsightsFeature>
    @Namespace private var animation
    
    // Derived state for the sheet presentation
    private var isPatternSheetPresented: Binding<Bool> {
        Binding(
            get: { store.selectedPattern != nil },
            set: { isPresented in
                if !isPresented {
                    store.send(.dismissPattern)
                }
            }
        )
    }
    
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
            .background(Color.ds.backgroundPrimary.ignoresSafeArea(edges: .bottom))
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 80) // Space for custom tab bar
            }
            .navigationTitle("Your Insights")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        DSHaptics.light()
                        store.send(.refresh)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .task {
                store.send(.task)
            }
            .sheet(isPresented: isPatternSheetPresented) {
                if let pattern = store.selectedPattern {
                    patternDetailSheet(pattern)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    private var periodSelector: some View {
        HStack(spacing: 0) {
            ForEach(InsightsFeature.State.Period.allCases) { period in
                periodButton(for: period)
            }
        }
        .background { Color.ds.accent.opacity(0.1) }
        .clipShape(Capsule())
        .padding(.horizontal, 4)
    }
    
    private func periodButton(for period: InsightsFeature.State.Period) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                _ = store.send(.selectPeriod(period))
            }
        } label: {
            Text(period.rawValue)
                .font(.ds.caption.weight(.semibold))
                .foregroundColor(store.selectedPeriod == period ? .white : .ds.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background {
                    if store.selectedPeriod == period {
                        Capsule()
                            .fill(Color.ds.accent)
                            .matchedGeometryEffect(id: "PERIOD_BG", in: animation)
                    } else {
                        Color.clear
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var insightsContent: some View {
        // Show empty state if no data
        if (store.trends?.sentimentTimeline.isEmpty ?? true) && 
           (store.insights?.overview.totalEntries ?? 0) == 0 {
            emptyStateView
        } else {
            if let recommendation = store.insights?.recommendation {
                aiRecommendationCard(recommendation)
            }
            
            if let insights = store.insights {
                overviewCard(insights.overview)
            }
            
            if let trends = store.trends, !trends.sentimentTimeline.isEmpty {
                sentimentChartCard(trends.sentimentTimeline)
            }
            
            if let correlations = store.insights?.correlations, correlations.moodActivityCorr != 0 {
                activityCorrelationCard(correlations)
            }
            
            if let timeData = store.insights?.timeOfDayAnalysis, !timeData.isEmpty {
                timeOfDayCard(timeData)
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
    
    private func aiRecommendationCard(_ recommendation: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.ds.accent)
                Text("Personalized AI Tip")
                    .font(.ds.headline)
                    .foregroundStyle(Color.ds.accent)
                Spacer()
            }
            
            Text(recommendation)
                .font(.ds.body)
                .lineSpacing(4)
                .foregroundStyle(.primary)
        }
        .padding(20)
        .background(
            ZStack {
                Color.ds.accent.opacity(0.05)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.ds.accent.opacity(0.1), lineWidth: 1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
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
                
                HStack(spacing: 12) {
                    StatBox(
                        value: "\(overview.totalEntries)",
                        label: "Entries",
                        color: .blue
                    )
                    
                    StatBox(
                        value: String(format: "%.0f%%", (overview.moodStability ?? 0.8) * 100),
                        label: "Stability",
                        color: .purple
                    )
                    
                    StatBox(
                        value: String(format: "%.0f%%", overview.avgSentiment * 100),
                        label: "Avg Mood",
                        color: sentimentColor(overview.avgSentiment)
                    )
                }
            }
        }
    }

    private func activityCorrelationCard(_ correlations: CorrelationDTO) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundStyle(.orange)
                    Text("Activity & Mood")
                        .font(.ds.headline)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(format: "+%.0f%%", correlations.moodBoostPct))
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundStyle(.orange)
                        Text("Mood Boost")
                            .font(.ds.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("On days when you are more physically active, your mood score increases by an average of \(String(format: "%.0f%%", correlations.moodBoostPct)).")
                            .font(.ds.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Progress bar style correlation indicator
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Correlation Strength")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.tertiary)
                        Spacer()
                        Text(correlations.moodActivityCorr > 0.5 ? "Strong" : "Moderate")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.orange)
                    }
                    
                    ProgressView(value: abs(correlations.moodActivityCorr), total: 1.0)
                        .tint(.orange)
                }
            }
        }
    }

    private func timeOfDayCard(_ data: [TimeOfDayAnalysisDTO]) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                    Text("Mood by Time of Day")
                        .font(.ds.headline)
                    Spacer()
                }
                
                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(data, id: \.timeOfDay) { item in
                        VStack(spacing: 8) {
                            Spacer(minLength: 0)
                            
                            Text(String(format: "%.0f", item.avgSentiment * 100))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(sentimentColor(item.avgSentiment))
                            
                            RoundedRectangle(cornerRadius: 6)
                                .fill(sentimentColor(item.avgSentiment).opacity(0.3))
                                .frame(width: 40, height: CGFloat(max(item.avgSentiment * 100, 10)))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(sentimentColor(item.avgSentiment).opacity(0.5), lineWidth: 1)
                                )
                            
                            Text(item.timeOfDay.capitalized)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 140)
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
                        .interpolationMethod(.catmullRom)
                        
                        AreaMark(
                            x: .value("Date", item.date),
                            y: .value("Sentiment", item.avgSentiment)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
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
                    Text("Cognitive Patterns")
                        .font(.ds.headline)
                    Spacer()
                }
                
                ForEach(patterns.indices, id: \.self) { index in
                    let pattern = patterns[index]
                    Button {
                        store.send(.patternTapped(pattern))
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color.purple.opacity(0.3))
                                .frame(width: 8, height: 8)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(pattern.description ?? "Pattern")
                                    .font(.ds.body)
                                    .multilineTextAlignment(.leading)
                                Text("Detected \(pattern.frequency) times")
                                    .font(.ds.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.up.circle.fill")
                                .foregroundStyle(.purple.opacity(0.5))
                                .rotationEffect(.degrees(90))
                        }
                    }
                    .buttonStyle(.plain)
                    
                    if index < patterns.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
    
    private func emotionsCard(_ emotions: [EmotionFrequencyDTO]) -> some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "face.smiling")
                        .foregroundStyle(.orange)
                    Text("Emotion Cloud")
                        .font(.ds.headline)
                    Spacer()
                }
                
                // Using a FlowLayout alternative (wrapping HStack)
                // Since native FlowLayout requires iOS 16+ Layout protocol,
                // we'll simulate it with a robust scrolling chip view for iOS 15+ compatibility
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(emotions.prefix(10), id: \.emotion) { emotion in
                            HStack(spacing: 6) {
                                Text(emotionEmoji(emotion.emotion))
                                    .font(.system(size: 18))
                                Text(emotion.emotion.capitalized)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.primary)
                                Text("\(emotion.count)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange.opacity(0.8))
                                    .clipShape(Capsule())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.orange.opacity(0.2), lineWidth: 1))
                        }
                    }
                    .padding(.vertical, 4)
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
    private func patternDetailSheet(_ pattern: CBTPatternFrequencyDTO) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundStyle(.purple)
                    .font(.title2)
                Text(pattern.description ?? "Cognitive Distortion")
                    .font(.ds.headline)
                Spacer()
                Button {
                    store.send(.dismissPattern)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("What is this?")
                    .font(.ds.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                
                Text(patternExplainer(pattern.description ?? ""))
                    .font(.ds.body)
                
                Divider()
                
                Text("How to reframe it")
                    .font(.ds.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                
                Text(patternReframe(pattern.description ?? ""))
                    .font(.ds.body)
                    .foregroundStyle(.purple)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.purple.opacity(0.05))
                    .cornerRadius(12)
            }
            
            Spacer()
            
            Button {
                store.send(.dismissPattern)
            } label: {
                Text("Got it")
                    .font(.ds.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.ds.accent)
                    .cornerRadius(16)
            }
        }
        .padding(24)
        .background(Color.ds.backgroundPrimary)
    }

    private func patternExplainer(_ description: String) -> String {
        let desc = description.lowercased()
        if desc.contains("catastrophizing") {
            return "Expecting the worst-case scenario to happen, even when it's unlikely."
        } else if desc.contains("black and white") || desc.contains("all or nothing") {
            return "Seeing things in only two categories (perfect or failure) with no middle ground."
        } else if desc.contains("mind reading") {
            return "Assuming you know what others are thinking, usually something negative about you."
        } else if desc.contains("overgeneralization") {
            return "Taking one single negative event and seeing it as a never-ending pattern of defeat."
        } else if desc.contains("personalization") {
            return "Blaming yourself for everything that goes wrong, even when it's not your fault."
        }
        return "This is a common thinking pattern that can make you feel more anxious or sad than the situation warrants."
    }

    private func patternReframe(_ description: String) -> String {
        let desc = description.lowercased()
        if desc.contains("catastrophizing") {
            return "Ask yourself: 'What is the most likely outcome?' and 'Could I handle the worst-case if it really happened?'"
        } else if desc.contains("black and white") {
            return "Try to find the 'shades of gray.' What parts of the situation are okay even if they aren't perfect?"
        } else if desc.contains("mind reading") {
            return "Remind yourself: 'I can't actually know what they're thinking. Is there a more neutral explanation?'"
        } else if desc.contains("overgeneralization") {
            return "Focus on the specific event. Just because this happened once doesn't mean it will always happen."
        }
        return "Try to look at the facts of the situation as if you were a neutral observer giving advice to a friend."
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
