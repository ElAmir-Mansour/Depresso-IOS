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
        var filteredPosts: [CommunityPost] {
            if selectedCategory == "All" {
                return posts
            } else {
                return posts.filter { $0.category == selectedCategory }
            }
        }
        var isLoading: Bool = true
        var errorMessage: String?
        var likedPostIDs: Set<UUID> = []
        var viewedPostIDs: Set<UUID> = []
        @Presents var destination: Destination.State?
        
        var selectedCategory: String = "All"
        var selectedView: ViewMode = .feed
        
        var trendingPosts: [CommunityPostDTO] = []
        var communityStats: CommunityStatsDTO? = nil
        
        var comments: [UUID: [Comment]] = [:]
        var showCommentsForPost: UUID?
        @Presents var alert: AlertState<Action.Alert>?
        
        enum ViewMode: String, CaseIterable, Identifiable {
            case feed = "Feed"
            case trending = "Trending"
            
            var id: String { rawValue }
        }
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
        case selectCategory(String)
        case selectView(State.ViewMode)
        case loadTrendingData
        case trendingDataLoaded(Result<([CommunityPostDTO], CommunityStatsDTO), Error>)
        case destination(PresentationAction<Destination.Action>)
        case postSavedSuccessfully(CommunityPost)
        case saveFailed(Error)
        case likeButtonTapped(id: CommunityPost.ID)
        case addComment(postId: UUID, text: String)
        case commentAdded(postId: UUID, comment: Comment)
        case viewPost(id: CommunityPost.ID)
        case commentsLoaded(postId: UUID, Result<[Comment], Error>)
        case reportPostTapped(id: CommunityPost.ID)
        case alert(PresentationAction<Alert>)
        
        enum Alert: Equatable {
            case confirmReport(id: CommunityPost.ID)
        }
    }



    @Dependency(\.modelContext) var modelContext
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    @MainActor
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                state.errorMessage = nil
                
                return .merge(
                    .run { [modelContext] send in
                        await MainActor.run {
                            let descriptor = FetchDescriptor<CommunityPost>(
                                sortBy: [SortDescriptor(\.creationDate, order: .reverse)]
                            )
                            if let localPosts = try? modelContext.context.fetch(descriptor) {
                                send(.postsLoaded(.success(localPosts)))
                            } else {
                                send(.postsLoaded(.success([])))
                            }
                        }
                    },
                    .run { [modelContext] send in
                        do {
                            let postsDTO = try await APIClient.getAllPosts()
                            
                            let posts = try await MainActor.run {
                                return try postsDTO.compactMap { dto -> CommunityPost? in
                                    guard let dtoID = UUID(uuidString: dto.id) else { return nil }
                                    
                                    let predicate = #Predicate<CommunityPost> { $0.id == dtoID }
                                    let descriptor = FetchDescriptor(predicate: predicate)
                                    
                                    if let existingPost = try modelContext.context.fetch(descriptor).first {
                                        existingPost.title = dto.title ?? ""
                                        existingPost.content = dto.content
                                        existingPost.likeCount = dto.likeCount
                                        return existingPost
                                    } else {
                                        let newPost = CommunityPost(
                                            id: dtoID,
                                            userId: "global",
                                            title: dto.title ?? "",
                                            content: dto.content,
                                            creationDate: dto.createdAt,
                                            category: "General",
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
                        }
                    },
                    .run { [userDefaultsClient] send in
                        do {
                            let userId = try await MainActor.run { try UserManager.shared.getCurrentUserId() }
                            let likedPostIdStrings = try await APIClient.getLikedPosts(userId: userId)
                            let likedPostIDs = Set(likedPostIdStrings.compactMap { UUID(uuidString: $0) })
                            await send(.likedIDsLoaded(likedPostIDs))
                        } catch {
                            let ids = await userDefaultsClient.loadLikedPostIDs()
                            await send(.likedIDsLoaded(ids))
                        }
                    }
                )


            case .postsLoaded(.success(let posts)):
                state.posts = posts
                state.isLoading = false
                return .none

            case .postsLoaded(.failure):
                state.isLoading = false
                state.errorMessage = "Failed to load community stories."
                return .none

            case .likedIDsLoaded(let ids):
                state.likedPostIDs = ids
                return .none

            case .selectCategory(let category):
                state.selectedCategory = category
                DSHaptics.selection()
                return .none
            
            case .selectView(let view):
                state.selectedView = view
                DSHaptics.selection()
                if view == .trending && state.trendingPosts.isEmpty {
                    return .send(.loadTrendingData)
                }
                return .none
            
            case .loadTrendingData:
                return .run { send in
                    await send(.trendingDataLoaded(Result {
                        async let trending = APIClient.getCommunityTrending()
                        async let stats = APIClient.getCommunityStats()
                        return try await (trending, stats)
                    }))
                }
            
            case .trendingDataLoaded(.success(let (trending, stats))):
                state.trendingPosts = trending
                state.communityStats = stats
                return .none
            
            case .trendingDataLoaded(.failure(let error)):
                print("❌ Failed to load trending data: \(error)")
                return .none

            case .addPostButtonTapped:
                state.destination = .addPost(AddPostFeature.State())
                return .none

            case .destination(.presented(.addPost(.delegate(.savePost(let draft))))):
                return .run { [modelContext] send in
                    do {
                        let userId = try await MainActor.run { try UserManager.shared.getCurrentUserId() }
                        
                        let postDTO = try await APIClient.createPost(
                            userId: userId,
                            title: draft.title,
                            content: draft.content
                        )
                        
                        await MainActor.run {
                            let savedPost = CommunityPost(
                                id: UUID(uuidString: postDTO.id) ?? UUID(),
                                userId: userId,
                                title: draft.title,
                                content: draft.content,
                                creationDate: postDTO.createdAt,
                                category: draft.category,
                                imageData: draft.imageData,
                                likeCount: 0
                            )
                            modelContext.context.insert(savedPost)
                            try? modelContext.context.save()
                            send(.postSavedSuccessfully(savedPost))
                        }
                    } catch {
                        await send(.saveFailed(error))
                    }
                }

            case .postSavedSuccessfully(let newPost):
                state.posts.insert(newPost, at: 0)
                state.destination = nil
                
                return .run { [modelContext] _ in
                    let userId = (try? await MainActor.run { try UserManager.shared.getCurrentUserId() }) ?? ""
                    if !userId.isEmpty {
                        _ = await AchievementManager.shared.checkAchievements(userId: userId, context: modelContext.context)
                    }
                }

            case .saveFailed:
                state.destination = nil
                return .none

            case .likeButtonTapped(let id):
                guard let index = state.posts.firstIndex(where: { $0.id == id }) else {
                    return .none
                }

                let post = state.posts[index]
                let wasLiked = state.likedPostIDs.contains(id)
                
                if wasLiked {
                    state.likedPostIDs.remove(id)
                    post.likeCount -= 1
                    DSHaptics.light()
                } else {
                    state.likedPostIDs.insert(id)
                    post.likeCount += 1
                    DSHaptics.success()
                }

                try? modelContext.context.save()

                let likedIDs = state.likedPostIDs
                
                return .run { [userDefaultsClient] _ in
                    do {
                        let userId = try await MainActor.run { try UserManager.shared.getCurrentUserId() }
                        let postIdString = id.uuidString
                        
                        if wasLiked {
                            try await APIClient.unlikePost(postId: postIdString, userId: userId)
                        } else {
                            try await APIClient.likePost(postId: postIdString, userId: userId)
                        }
                        await userDefaultsClient.saveLikedPostIDs(likedIDs)
                    } catch {
                        print("❌ Failed to sync like with backend: \(error)")
                    }
                }
                
            case .addComment(let postId, let text):
                // Create an optimistic local comment
                let optimisticComment = Comment(id: UUID(), author: "You", content: text, date: Date())
                var currentComments = state.comments[postId] ?? []
                currentComments.append(optimisticComment)
                state.comments[postId] = currentComments
                DSHaptics.success()
                
                return .run { send in
                    do {
                        let userId = try await MainActor.run { try UserManager.shared.getCurrentUserId() }
                        let commentDTO = try await APIClient.addComment(postId: postId.uuidString, userId: userId, content: text)
                        
                        let backendComment = Comment(
                            id: UUID(uuidString: commentDTO.id) ?? UUID(),
                            author: "You", // Backend might not have names, but we know it's "You" for the local user
                            content: commentDTO.content,
                            date: commentDTO.createdAt
                        )
                        await send(.commentAdded(postId: postId, comment: backendComment))
                    } catch {
                        print("❌ Failed to add comment: \(error)")
                    }
                }
                
            case .commentAdded(let postId, let comment):
                // Replace optimistic comment with the real one, or just re-fetch
                // We'll just fetch all comments to ensure we have the most up-to-date state
                return .run { send in
                    do {
                        let commentDTOs = try await APIClient.getComments(postId: postId.uuidString)
                        let comments = commentDTOs.map { dto in
                            Comment(
                                id: UUID(uuidString: dto.id) ?? UUID(),
                                author: "Anonymous", // Ideally, backend includes the author name or we use pseudo identity
                                content: dto.content,
                                date: dto.createdAt
                            )
                        }
                        await send(.commentsLoaded(postId: postId, .success(comments)))
                    } catch {
                        await send(.commentsLoaded(postId: postId, .failure(error)))
                    }
                }

            case .viewPost(let id):
                var effects: [Effect<Action>] = []
                
                if !state.viewedPostIDs.contains(id) {
                    state.viewedPostIDs.insert(id)
                    effects.append(.run { _ in
                        do {
                            let userId = try await MainActor.run { try UserManager.shared.getCurrentUserId() }
                            try await APIClient.trackAnalytics(userId: userId, eventType: "view", postId: id.uuidString)
                        } catch {}
                    })
                }
                
                effects.append(.run { send in
                    do {
                        let commentDTOs = try await APIClient.getComments(postId: id.uuidString)
                        let comments = commentDTOs.map { dto in
                            Comment(
                                id: UUID(uuidString: dto.id) ?? UUID(),
                                author: dto.userId, // We can use PseudoIdentity in the View with this userId
                                content: dto.content,
                                date: dto.createdAt
                            )
                        }
                        await send(.commentsLoaded(postId: id, .success(comments)))
                    } catch {
                        await send(.commentsLoaded(postId: id, .failure(error)))
                    }
                })
                
                return .merge(effects)
                
            case .commentsLoaded(let postId, .success(let comments)):
                state.comments[postId] = comments
                return .none
                
            case .commentsLoaded(_, .failure(let error)):
                print("❌ Failed to load comments: \(error)")
                return .none
                
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
                return .run { _ in
                    print("reported post \(id)")
                }
                
            case .alert, .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$alert, action: \.alert)
    }
}
