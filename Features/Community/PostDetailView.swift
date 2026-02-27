// In Features/Community/PostDetailView.swift
import SwiftUI
import ComposableArchitecture
import SwiftData

struct PostDetailView: View {
    // Receives the store to enable interactivity
    let store: StoreOf<CommunityFeature>
    let post: CommunityPost

    private var postImage: Image? {
         guard let data = post.imageData, let uiImage = UIImage(data: data) else { return nil }
         return Image(uiImage: uiImage)
     }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                // User Info Header
                 HStack(alignment: .top, spacing: DesignSystem.Spacing.small) {
                     Image(systemName: "person.circle.fill")
                         .resizable().scaledToFit().frame(width: 40, height: 40)
                         .foregroundStyle(.gray.opacity(0.5))
                     VStack(alignment: .leading) {
                         Text("Anonymous User").font(.ds.caption.weight(.semibold))
                         Text("Posted \(post.creationDate, style: .relative) ago").font(.ds.caption).foregroundStyle(.secondary)
                     }
                     Spacer()
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
                            if post.likeCount > 0 {
                                Text("\(post.likeCount)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.top, DesignSystem.Spacing.small)

            }
            .padding()
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
