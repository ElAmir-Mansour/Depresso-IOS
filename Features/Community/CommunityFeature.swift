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
        
        var comments: [UUID: [Comment]] = [:]
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
        case selectCategory(String)
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
                    .run { send in
                        do {
                            await send(.likedIDsLoaded(Set<UUID>()))
                        } catch {
                            await send(.likedIDsLoaded(Set<UUID>()))
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

            case .viewPost(let id):
                if state.viewedPostIDs.contains(id) { return .none }
                state.viewedPostIDs.insert(id)
                
                return .run { _ in
                    do {
                        let userId = try await MainActor.run { try UserManager.shared.getCurrentUserId() }
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
