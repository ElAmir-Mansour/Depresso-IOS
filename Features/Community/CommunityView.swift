// In Features/Community/CommunityView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct CommunityView: View {
    @Bindable var store: StoreOf<CommunityFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // View Mode Selector (Feed / Trending)
                viewModeSelector
                
                // Category Filter Bar (only show in feed mode)
                if store.selectedView == .feed {
                    categoryFilterBar
                }
                
                ZStack {
                    if store.selectedView == .trending {
                        trendingContent
                    } else {
                        feedContent
                    }
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        store.send(.addPostButtonTapped)
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .task {
                store.send(.task)
            }
            .sheet(item: $store.scope(state: \.destination?.addPost, action: \.destination.addPost)) { addPostStore in
                AddPostView(store: addPostStore)
            }
        }
    }
    
    private var viewModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(CommunityFeature.State.ViewMode.allCases) { mode in
                Button {
                    store.send(.selectView(mode))
                } label: {
                    Text(mode.rawValue)
                        .font(.ds.body.weight(.semibold))
                        .foregroundColor(store.selectedView == mode ? .white : .ds.accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(store.selectedView == mode ? Color.ds.accent : Color.clear)
                }
            }
        }
        .background(Color.ds.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
    }
    
    @ViewBuilder
    private var feedContent: some View {
        if store.isLoading {
            loadingView
        } else if let errorMessage = store.errorMessage {
            DSEmptyState(
                icon: "exclamationmark.triangle",
                title: "Error",
                message: errorMessage
            )
        } else if store.filteredPosts.isEmpty {
            DSEmptyState(
                icon: "text.bubble",
                title: store.selectedCategory == "All" ? "No Stories Yet" : "No \(store.selectedCategory) Stories",
                message: "Be the first to share your journey in this category.",
                actionTitle: "Share Your Story",
                action: { store.send(.addPostButtonTapped) }
            )
        } else {
            postsList
        }
    }
    
    @ViewBuilder
    private var trendingContent: some View {
        if let stats = store.communityStats {
            CommunityTrendsView(
                trendingPosts: store.trendingPosts,
                stats: stats,
                onPostTap: { postId in
                    // Navigate to post detail
                    if let uuid = UUID(uuidString: postId) {
                        store.send(.viewPost(id: uuid))
                    }
                }
            )
        } else {
            VStack {
                ProgressView()
                Text("Loading trending data...")
                    .font(.ds.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var categoryFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryButton(title: "All", icon: "square.grid.2x2.fill")
                
                ForEach(CommunityCategory.allCases) { category in
                    categoryButton(title: category.rawValue, icon: category.icon)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color.ds.backgroundPrimary)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 5)
    }
    
    private func categoryButton(title: String, icon: String) -> some View {
        let isSelected = store.selectedCategory == title
        
        return Button {
            store.send(.selectCategory(title))
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.ds.accent : Color.ds.accent.opacity(0.1))
            .foregroundColor(isSelected ? .white : .ds.accent)
            .clipShape(Capsule())
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
    
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                DSSkeletonPost()
                DSSkeletonPost()
                DSSkeletonPost()
            }
            .padding()
        }
    }
    
    private var postsList: some View {
        List {
            ForEach(store.filteredPosts) { post in
                NavigationLink {
                    PostDetailView(store: store, post: post)
                } label: {
                    PostRowView(store: store, post: post)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 16))
            }
        }
        .listStyle(.plain)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80)
        }
    }
}

// --- Updated PostRowView with Category Badge ---
struct PostRowView: View {
    let store: StoreOf<CommunityFeature>
    let post: CommunityPost

    private var postImage: Image? {
        guard let data = post.imageData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
            Image(systemName: "person.circle.fill")
                .resizable().scaledToFit().frame(width: 40, height: 40)
                .foregroundStyle(.gray.opacity(0.5))
                .padding(.leading, DesignSystem.Spacing.medium)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Anonymous User").font(.ds.caption.weight(.semibold))
                        HStack {
                            Text(post.creationDate, style: .relative).font(.ds.caption).foregroundStyle(.secondary)
                            Text("·").font(.ds.caption).foregroundStyle(.secondary)
                            
                            // Category Badge
                            Text(post.category)
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.ds.accent.opacity(0.1))
                                .foregroundColor(.ds.accent)
                                .clipShape(Capsule())
                        }
                    }
                    Spacer()
                }
                
                if !post.title.isEmpty {
                    Text(post.title).font(.ds.headline).padding(.bottom, 2)
                }
                
                Text(post.content).font(.ds.body).lineLimit(3).foregroundStyle(.secondary)
                
                if let image = postImage {
                    image
                        .resizable().scaledToFill().frame(height: 150)
                        .clipped().cornerRadius(12)
                        .padding(.top, DesignSystem.Spacing.extraSmall)
                }

                HStack(spacing: DesignSystem.Spacing.medium) {
                    let isLiked = store.likedPostIDs.contains(post.id)
                    
                    Button {
                        store.send(.likeButtonTapped(id: post.id))
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(isLiked ? .red : .secondary)
                                .symbolEffect(.bounce, value: isLiked)
                                .sensoryFeedback(.success, trigger: isLiked)
                            
                            if post.likeCount > 0 {
                                Text("\(post.likeCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .contentTransition(.numericText())
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(isLiked ? Color.red.opacity(0.1) : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    
                    Button {
                        // Share action
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.secondary)
                .padding(.top, DesignSystem.Spacing.small)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.extraSmall)
    }
}

#Preview {
    let container = try! ModelContainer(for: CommunityPost.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    let context = container.mainContext
    
    let samplePosts = [
        CommunityPost(userId: "preview", title: "Finding Hope", content: "Today was a good day. I finally managed to take a walk and breathe properly.", category: "Recovery", likeCount: 5),
        CommunityPost(userId: "preview", title: "Small Wins", content: "Managed to journal for 5 minutes today. It's a start.", category: "Daily Wins")
    ]
    
    let _ = samplePosts.forEach { context.insert($0) }

    let store = Store(initialState: CommunityFeature.State(posts: samplePosts, isLoading: false)) {
        CommunityFeature()
            .dependency(\.modelContext, try! ModelContextBox(context))
    }

    NavigationStack {
        CommunityView(store: store)
            .modelContainer(container)
    }
}
