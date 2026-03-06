// In Features/Community/CommunityView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct CommunityView: View {
    @Bindable var store: StoreOf<CommunityFeature>
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            mainContentContainer
                .navigationTitle("Community")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            DSHaptics.buttonPress()
                            store.send(.addPostButtonTapped)
                        } label: {
                            Image(systemName: "square.and.pencil")
                        }
                    }
                }
                .task {
                    store.send(.task)
                }
                .overlay(alignment: .bottomTrailing) {
                    floatingActionButton
                }
                .sheet(item: $store.scope(state: \.destination?.addPost, action: \.destination.addPost)) { addPostStore in
                    AddPostView(store: addPostStore)
                }
        }
    }
    
    private var mainContentContainer: some View {
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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.ds.backgroundPrimary.ignoresSafeArea(edges: .bottom))
    }
    
    private var floatingActionButton: some View {
        Button {
            DSHaptics.buttonPress()
            store.send(.addPostButtonTapped)
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(.title3.weight(.bold))
                Text("Share Story")
                    .font(.headline)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color.ds.accent)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .shadow(color: Color.ds.accent.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding()
        .padding(.bottom, 80) // Push above custom tab bar
    }
    
    private var viewModeSelector: some View {
        HStack(spacing: 0) {
            ForEach(CommunityFeature.State.ViewMode.allCases, id: \.self) { mode in
                viewModeButton(for: mode)
            }
        }
        .background {
            Color.ds.accent.opacity(0.1)
        }
        .clipShape(Capsule())
        .padding()
    }
    
    private func viewModeButton(for mode: CommunityFeature.State.ViewMode) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                _ = store.send(.selectView(mode))
            }
        } label: {
            Text(mode.rawValue)
                .font(.ds.body.weight(.semibold))
                .foregroundColor(store.selectedView == mode ? Color.white : Color.ds.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background {
                    if store.selectedView == mode {
                        Capsule()
                            .fill(Color.ds.accent)
                            .matchedGeometryEffect(id: "VIEW_MODE_BG", in: animation)
                    } else {
                        Color.clear
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var feedContent: some View {
        if store.isLoading {
            loadingView
        } else if let errorMessage = store.errorMessage {
            DSEmptyState(
                icon: DSIcons.errorState,
                title: "Something went wrong",
                message: errorMessage
            )
        } else if store.filteredPosts.isEmpty {
            DSEmptyState(
                icon: DSIcons.emptyState,
                title: store.selectedCategory == "All" ? "No Stories Yet" : "No \(store.selectedCategory) Stories",
                message: "Be the first to share your journey in this category.",
                actionTitle: "Share Your Story",
                action: { store.send(.addPostButtonTapped) }
            )
        }
 else {
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

// --- Pseudo Identity Helper ---
struct PseudoIdentity {
    let name: String
    let color: Color
    let icon: String
    
    init(userId: String) {
        let names = ["Mindful Friend", "Brave Journey", "Gentle Soul", "Quiet Strength", "Hopeful Heart", "Peace Seeker", "Inner Light", "Calm Waters"]
        let colors: [Color] = [.blue, .purple, .orange, .green, .pink, .teal, .indigo, .mint]
        let icons = ["leaf.fill", "sparkles", "sun.max.fill", "moon.stars.fill", "bird.fill", "drop.fill", "heart.circle.fill", "star.circle.fill"]
        
        let hash = abs(userId.hashValue)
        self.name = names[hash % names.count]
        self.color = colors[hash % colors.count]
        self.icon = icons[hash % icons.count]
    }
}

// --- Updated PostRowView with Category Badge & Pseudo Identity ---
struct PostRowView: View {
    let store: StoreOf<CommunityFeature>
    let post: CommunityPost

    private var postImage: Image? {
        guard let data = post.imageData, let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }

    var body: some View {
        let identity = PseudoIdentity(userId: post.userId)
        
        HStack(alignment: .top, spacing: DesignSystem.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(identity.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: identity.icon)
                    .foregroundColor(identity.color)
                    .font(.system(size: 20))
            }
            .padding(.leading, DesignSystem.Spacing.medium)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(identity.name).font(.ds.caption.weight(.semibold)).foregroundColor(identity.color)
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

                    Button {
                        // Action handled by NavigationLink in CommunityView
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "bubble.right")
                                .foregroundStyle(.secondary)
                            
                            let actualCount = store.comments[post.id]?.count ?? 0
                            
                            if actualCount > 0 {
                                Text("\(actualCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                    
                    ShareLink(item: "\(post.title.isEmpty ? "A story" : post.title) on Depresso\n\n\(post.content)") {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 8)
                    }
                    .buttonStyle(.plain)
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
