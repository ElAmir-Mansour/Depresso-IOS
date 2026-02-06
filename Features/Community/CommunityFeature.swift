// In Features/Community/CommunityFeature.swift
import Foundation
import ComposableArchitecture
import SwiftData
import SwiftUI

@Reducer
struct CommunityFeature {
    @ObservableState
    struct State: Equatable {
        var posts: [CommunityPost] = []
        var isLoading: Bool = true
        var errorMessage: String?
        var likedPostIDs: Set<UUID> = []
        var viewedPostIDs: Set<UUID> = [] // De-duplication for session views
        @Presents var destination: Destination.State?
        
        // Comment management
        var comments: [UUID: [Comment]] = [:] // Map post ID to comments
        var showCommentsForPost: UUID?
        @Presents var alert: AlertState<Action.Alert>?
    }

    @Reducer(state: .equatable)
    enum Destination {
        case addPost(AddPostFeature)
    }

    enum Action {
        case task
        case postsLoaded(Result<[CommunityPost], Error>)
        case likedIDsLoaded(Set<UUID>)
        case addPostButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case postSavedSuccessfully(CommunityPost)
        case saveFailed(Error)
        case likeButtonTapped(id: CommunityPost.ID)
        case viewPost(id: CommunityPost.ID)
        case reportPostTapped(id: CommunityPost.ID)
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            case confirmReport(id: CommunityPost.ID)
        }
    }



    @Dependency(\.modelContext) var modelContext
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    @MainActor // Ensures reducer runs on the main actor
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
    state.isLoading = true
    state.errorMessage = nil
    
    // Load from local SwiftData first (offline-first approach)
    return .merge(
        .run { [modelContext] send in
            await MainActor.run {
                let descriptor = FetchDescriptor<CommunityPost>(
                    sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                )
                if let localPosts = try? modelContext.context.fetch(descriptor) {                    send(.postsLoaded(.success(localPosts)))
                } else {
                    send(.postsLoaded(.success([])))
                }
            }
        },
        // Try to sync with backend in background (don't crash if it fails)
        .run { [modelContext] send in
            do {
                // Ensure user is registered first
                try await UserManager.shared.ensureUserRegistered()
                
                // Fetch from backend
                let postsDTO = try await APIClient.getAllPosts()
                
                // Convert DTOs to local models
                let posts = try await MainActor.run {
                    return try postsDTO.compactMap { dto -> CommunityPost? in
                        guard let dtoID = UUID(uuidString: dto.id) else { return nil }
                        
                        // Check if post already exists locally
                        // Use UUID comparison which is safer for SwiftData predicates
                        let predicate = #Predicate<CommunityPost> { $0.id == dtoID }
                        let descriptor = FetchDescriptor(predicate: predicate)
                        
                        if let existingPost = try modelContext.context.fetch(descriptor).first {
                            // Update existing post
                            existingPost.title = dto.title ?? ""
                            existingPost.content = dto.content
                            existingPost.likeCount = dto.likeCount
                            return existingPost
                        } else {
                            // Create new post
                            let newPost = CommunityPost(
                                id: dtoID,
                                title: dto.title ?? "",
                                content: dto.content,
                                creationDate: dto.createdAt,
                                imageData: nil,
                                likeCount: dto.likeCount
                            )
                            modelContext.context.insert(newPost)
                            return newPost
                        }
                    }
                }
                
                await MainActor.run {
                    try? modelContext.context.save()
                }
                await send(.postsLoaded(.success(posts)))
                
            } catch {
                print("❌ Error syncing with backend: \(error)")
                // Don't crash - we already loaded local posts
            }
        },
        // Load liked post IDs - don't crash if this fails
        .run { send in
            do {
                // Try to load from UserDefaults as fallback
                await send(.likedIDsLoaded(Set<UUID>()))
            } catch {
                print("❌ Error loading liked posts: \(error)")
                await send(.likedIDsLoaded(Set<UUID>()))
            }
        }
    )


            case .postsLoaded(.success(let posts)):
                state.posts = posts
                state.isLoading = false
                return .none

            case .postsLoaded(.failure(let error)):
                state.isLoading = false
                state.errorMessage = "Failed to load community stories."
                print("Error loading community posts: \(error)")
                return .none

            case .likedIDsLoaded(let ids):
                state.likedPostIDs = ids
                return .none

            case .addPostButtonTapped:
                state.destination = .addPost(AddPostFeature.State())
                return .none

            // Received 'savePost' delegate action from AddPostFeature
            case .destination(.presented(.addPost(.delegate(.savePost(let newPost))))):
    // Extract post data BEFORE async operations (avoid capturing non-Sendable CommunityPost)
    let postTitle = newPost.title
    let postContent = newPost.content
    let postImageData = newPost.imageData
    
    // CHANGED: Save to backend first, then local
    return .run { [modelContext] send in
        do {
            // Ensure user is registered first
            try await UserManager.shared.ensureUserRegistered()
            let userId = try await UserManager.shared.getCurrentUserId()
            
            // Save to backend
            let postDTO = try await APIClient.createPost(
                userId: userId,
                title: postTitle,
                content: postContent
            )
            
            // Create and save post locally on MainActor
            await MainActor.run {
                let savedPost = CommunityPost(
                    id: UUID(uuidString: postDTO.id) ?? UUID(),
                    title: postTitle,
                    content: postContent,
                    creationDate: postDTO.createdAt,
                    imageData: postImageData,
                    likeCount: 0
                )
                modelContext.context.insert(savedPost)
                try? modelContext.context.save()
                send(.postSavedSuccessfully(savedPost))
            }
            
            print("✅ Post saved to backend and locally")
            
        } catch {
            print("❌ Failed to save post to backend: \(error)")
            await send(.saveFailed(error))
        }
    }

            case .postSavedSuccessfully(let newPost):
                state.posts.insert(newPost, at: 0)
                state.destination = nil
                return .none

            case .saveFailed(let error):
                print("Error saving post: \(error)")
                state.destination = nil
                // Optionally show an alert here
                return .none

            case .likeButtonTapped(let id):
    guard let index = state.posts.firstIndex(where: { $0.id == id }) else {
        return .none
    }

    let post = state.posts[index]
    let wasLiked = state.likedPostIDs.contains(id)
    
    // Optimistic update
    if wasLiked {
        state.likedPostIDs.remove(id)
        post.likeCount -= 1
        DSHaptics.light() // Subtle haptic for unlike
    } else {
        state.likedPostIDs.insert(id)
        post.likeCount += 1
        DSHaptics.success() // Success haptic for liking!
    }

    // Save context
    try? modelContext.context.save()

    let likedIDs = state.likedPostIDs
    
    // CHANGED: Sync with backend
    return .run { [userDefaultsClient] _ in
        do {
            // Ensure user is registered first
            try await UserManager.shared.ensureUserRegistered()
            let userId = try await UserManager.shared.getCurrentUserId()
            let postIdString = id.uuidString
            
            if wasLiked {
                try await APIClient.unlikePost(postId: postIdString, userId: userId)
                print("✅ Post unliked on backend")
            } else {
                try await APIClient.likePost(postId: postIdString, userId: userId)
                print("✅ Post liked on backend")
            }
            
            // Save liked IDs locally
            await userDefaultsClient.saveLikedPostIDs(likedIDs)
            
        } catch {
            print("❌ Failed to sync like with backend: \(error)")
            // You might want to rollback the optimistic update here
        }
    }

            case .viewPost(let id):
                if state.viewedPostIDs.contains(id) { return .none }
                state.viewedPostIDs.insert(id)
                
                return .run { _ in
                    do {
                        try await UserManager.shared.ensureUserRegistered()
                        let userId = try await UserManager.shared.getCurrentUserId()
                        try await APIClient.trackAnalytics(userId: userId, eventType: "view", postId: id.uuidString)
                    } catch {}
                }
                
            case .reportPostTapped(let id):
                state.alert = AlertState {
                    TextState("Report Content")
                } actions: {
                    ButtonState(role: .destructive, action: .confirmReport(id: id)) {
                        TextState("Report")
                    }
                    ButtonState(role: .cancel) {
                        TextState("Cancel")
                    }
                } message: {
                    TextState("Are you sure you want to report this content? It will be reviewed by our moderation team.")
                }
                return .none
                
            case .alert(.presented(.confirmReport(let id))):
                // Handle report confirmation
                return .run { _ in
                    // Call report API
                    print("reported post \(id)")
                }
                
            case .alert:
                return .none

            case .destination(.dismiss):
                 state.destination = nil
                 return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$alert, action: \.alert)
    }
}
