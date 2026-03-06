// In Features/Community/PostDetailView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct PostDetailView: View {
    // Receives the store to enable interactivity
    let store: StoreOf<CommunityFeature>
    let post: CommunityPost
    @State private var newComment: String = ""
    @FocusState private var isInputFocused: Bool

    private var postImage: Image? {
         guard let data = post.imageData, let uiImage = UIImage(data: data) else { return nil }
         return Image(uiImage: uiImage)
     }

    var body: some View {
        let identity = PseudoIdentity(userId: post.userId)
        let actualComments = store.comments[post.id] ?? []

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                    // User Info Header
                     HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                         ZStack {
                             Circle()
                                 .fill(identity.color.opacity(0.2))
                                 .frame(width: 40, height: 40)
                             Image(systemName: identity.icon)
                                 .foregroundColor(identity.color)
                                 .font(.system(size: 20))
                         }
                         VStack(alignment: .leading) {
                             Text(identity.name).font(.ds.caption.weight(.semibold)).foregroundColor(identity.color)
                             Text("Posted \(post.creationDate, style: .relative) ago").font(.ds.caption).foregroundStyle(.secondary)
                         }
                         Spacer()

                         Text(post.category)
                             .font(.system(size: 10, weight: .bold))
                             .padding(.horizontal, 8)
                             .padding(.vertical, 4)
                             .background(Color.ds.accent.opacity(0.1))
                             .foregroundColor(.ds.accent)
                             .clipShape(Capsule())
                     }

                     // Title
                     if !post.title.isEmpty {
                         Text(post.title).font(.ds.title)
                     }

                     // Image
                     if let image = postImage {
                         image
                             .resizable().scaledToFit().frame(maxWidth: .infinity)
                             .cornerRadius(8)
                     }

                     // Full Content
                     Text(post.content).font(.ds.body)

                    Divider()

                    // Interactive Action Buttons Row
                    HStack(spacing: DesignSystem.Spacing.medium) {
                        let isLiked = store.likedPostIDs.contains(post.id)

                        Button {
                            store.send(.likeButtonTapped(id: post.id))
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isLiked ? "heart.fill" : "heart")
                                    .foregroundStyle(isLiked ? .red : .secondary)
                                    .symbolEffect(.bounce, value: isLiked)
                                if post.likeCount > 0 {
                                    Text("\(post.likeCount)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .contentTransition(.numericText())
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(isLiked ? Color.red.opacity(0.1) : Color.clear)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .foregroundStyle(.secondary)
                            let totalCount = actualComments.count
                            if totalCount > 0 {
                                Text("\(totalCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)

                        Spacer()

                        ShareLink(item: "\(post.title.isEmpty ? "A story" : post.title) on Depresso\n\n\(post.content)") {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                        }
                    }
                    .padding(.top, DesignSystem.Spacing.small)

                    // Comments Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                        Text("Comments")
                            .font(.ds.headline)
                            .padding(.top, DesignSystem.Spacing.medium)

                        if actualComments.isEmpty {
                            DSEmptyState(icon: "bubble.left.and.bubble.right", title: "No Comments Yet", message: "Be the first to share your thoughts.")
                        } else {
                            // Actual Comments
                            ForEach(actualComments) { comment in
                                let isYou = comment.author == "You"
                                let commentIdentity = PseudoIdentity(userId: isYou ? "current_user_placeholder" : comment.author)

                                HStack(alignment: .top, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(commentIdentity.color.opacity(0.2))
                                            .frame(width: 32, height: 32)
                                        Image(systemName: isYou ? "person.fill" : commentIdentity.icon)
                                            .foregroundColor(commentIdentity.color)
                                            .font(.system(size: 14))
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(isYou ? "You" : commentIdentity.name)
                                                .font(.ds.caption.weight(.semibold))
                                                .foregroundColor(commentIdentity.color)
                                            Spacer()
                                            Text(comment.date, style: .relative)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                        Text(comment.content)
                                            .font(.ds.caption)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)

            // Add Comment Bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Add a comment...", text: $newComment, axis: .vertical)
                        .padding(12)
                        .background(Color(UIColor.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.ds.border ?? .gray.opacity(0.3), lineWidth: 1)
                        )
                        .focused($isInputFocused)
                        .lineLimit(1...6)
                        .frame(minHeight: 44)
                    
                    Button {
                        if !newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            DSHaptics.buttonPress()
                            store.send(.addComment(postId: post.id, text: newComment))
                            newComment = ""
                            isInputFocused = false
                        }
                    } label: {
                        Image(systemName: "arrow.up")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(newComment.isEmpty ? Color.gray.opacity(0.5) : Color.ds.accent)
                            )
                            .shadow(color: newComment.isEmpty ? .clear : Color.ds.accent.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .disabled(newComment.isEmpty)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                if !isInputFocused {
                    Color.clear.frame(height: 80) // Padding for custom tab bar
                }
            }
            .background(Color(UIColor.secondarySystemBackground).ignoresSafeArea(edges: .bottom))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: -4)
        }
        .onTapGesture {
            isInputFocused = false
        }
        .navigationTitle(post.title.isEmpty ? "Story" : post.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Preview
#Preview {
     let container = try! ModelContainer(for: CommunityPost.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
     let context = container.mainContext
     let previewImageData = UIImage(systemName: "photo")?.jpegData(compressionQuality: 0.8)
     let samplePost = CommunityPost(userId: "preview", title: "Detail View Title", content: "This is the full content of the post...", imageData: previewImageData, likeCount: 12)
     let _ = { context.insert(samplePost) }()

     let store = Store(initialState: CommunityFeature.State(posts: [samplePost], isLoading: false, likedPostIDs: [])) {
        CommunityFeature()
     }

     NavigationStack {
         PostDetailView(store: store, post: samplePost)
     }
     .modelContainer(container)
}
