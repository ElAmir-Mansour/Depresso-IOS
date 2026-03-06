// Features/Community/CommunityTrendsView.swift
import SwiftUI
import ComposableArchitecture

struct CommunityTrendsView: View {
    let trendingPosts: [CommunityPostDTO]
    let stats: CommunityStatsDTO
    let onPostTap: (String) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
                // Stats Overview
                statsSection
                
                // Sentiment Distribution
                if !stats.sentimentDistribution.isEmpty {
                    sentimentSection
                }
                
                // Trending Posts
                trendingSection
            }
            .padding()
        }
        .background(Color.ds.backgroundPrimary)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80)
        }
    }
    
    private var statsSection: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.purple)
                    Text("Community Stats")
                        .font(.ds.headline)
                    Spacer()
                }
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatItem(icon: "doc.text", value: "\(stats.overview.totalPosts)", label: "Total Posts", color: .blue)
                    StatItem(icon: "heart.fill", value: "\(stats.overview.totalLikes)", label: "Total Likes", color: .pink)
                    StatItem(icon: "person.3", value: "\(stats.overview.activeUsers)", label: "Active Users", color: .purple)
                    StatItem(icon: "calendar", value: "\(stats.overview.postsThisWeek)", label: "This Week", color: .green)
                }
            }
        }
    }
    
    private var sentimentSection: some View {
        DSCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "face.smiling")
                        .foregroundStyle(.orange)
                    Text("Community Mood")
                        .font(.ds.headline)
                    Spacer()
                }
                
                ForEach(stats.sentimentDistribution, id: \.sentiment) { dist in
                    HStack {
                        sentimentEmoji(dist.sentiment)
                        Text(dist.sentiment.capitalized)
                            .font(.ds.body)
                        Spacer()
                        Text("\(dist.count) posts")
                            .font(.ds.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: "%.0f%%", (Double(dist.count) / Double(stats.overview.totalPosts)) * 100))
                            .font(.ds.caption.weight(.bold))
                            .foregroundStyle(sentimentColor(dist.sentiment))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.red)
                Text("Trending Posts")
                    .font(.ds.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            if trendingPosts.isEmpty {
                DSEmptyState(
                    icon: "flame",
                    title: "No Trending Posts Yet",
                    message: "Posts with likes will appear here"
                )
            } else {
                ForEach(trendingPosts, id: \.id) { post in
                    TrendingPostCard(post: post, onTap: { onPostTap(post.id) })
                }
            }
        }
    }
    
    private func sentimentEmoji(_ sentiment: String) -> some View {
        Text(sentiment == "positive" ? "😊" : sentiment == "negative" ? "😔" : "😐")
            .font(.title2)
    }
    
    private func sentimentColor(_ sentiment: String) -> Color {
        sentiment == "positive" ? .green : sentiment == "negative" ? .red : .orange
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title3, design: .rounded).weight(.bold))
                Text(label)
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TrendingPostCard: View {
    let post: CommunityPostDTO
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            DSCard {
                VStack(alignment: .leading, spacing: 12) {
                    if let title = post.title, !title.isEmpty {
                        Text(title)
                            .font(.ds.headline)
                            .foregroundStyle(.primary)
                    }
                    
                    Text(post.content)
                        .font(.ds.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.pink)
                            Text("\(post.likeCount)")
                                .font(.ds.caption.weight(.semibold))
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundStyle(.red)
                            Text("Trending")
                                .font(.ds.caption.weight(.bold))
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }
}
