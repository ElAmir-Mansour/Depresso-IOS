// In Features/Community/AddPostView.swift
import SwiftUI
import ComposableArchitecture
import PhotosUI 

struct AddPostView: View {
    @Bindable var store: StoreOf<AddPostFeature>

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $store.title)
                        .font(.ds.headline)
                } header: {
                    Text("Title")
                }
                
                Section {
                    ZStack(alignment: .topLeading) {
                        if store.content.isEmpty {
                            Text("Share your story...")
                                .foregroundStyle(Color.ds.textTertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        
                        TextEditor(text: $store.content)
                            .frame(minHeight: 200)
                            .scrollContentBackground(.hidden) // Make background transparent
                    }
                } header: {
                    Text("Your Story")
                }
                
                Section {
                    if let data = store.selectedImageData, let uiImage = UIImage(data: data) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 250)
                                .cornerRadius(12)
                            
                            Button {
                                store.selectedPhotoItem = nil // Triggers binding action to clear
                                store.selectedImageData = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .background(Circle().fill(Color.black.opacity(0.6)))
                            }
                            .padding(8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } else {
                        PhotosPicker(selection: $store.selectedPhotoItem, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                    .font(.title3)
                                Text("Select Photo")
                                    .font(.ds.body)
                                Spacer()
                            }
                            .padding(.vertical, 4)
                            .foregroundStyle(Color.ds.accent)
                        }
                    }
                } header: {
                    Text("Add Image (Optional)")
                }
            }
            .navigationTitle("New Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        DSHaptics.light()
                        store.send(.cancelButtonTapped)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        DSHaptics.buttonPress()
                        store.send(.saveButtonTapped)
                    }
                    .disabled(!store.isValid)
                }
            }
            .overlay {
                if store.isSaving {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        ProgressView()
                            .padding(24)
                            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}

#Preview {
    AddPostView(
        store: Store(initialState: AddPostFeature.State()) {
            AddPostFeature()
        }
    )
    .modelContainer(for: CommunityPost.self, inMemory: true)
}
