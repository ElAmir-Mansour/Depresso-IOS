// In Features/Community/AddPostView.swift
import SwiftUI
import ComposableArchitecture
import PhotosUI 

struct AddPostView: View {
    @Bindable var store: StoreOf<AddPostFeature>
    @FocusState private var isContentFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Premium Navigation Bar
                HStack {
                    Button {
                        DSHaptics.light()
                        store.send(.cancelButtonTapped)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                            .background(Color.ds.backgroundSecondary)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                        Text("Anonymous")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(Color.ds.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.ds.accent.opacity(0.1))
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        DSHaptics.buttonPress()
                        store.send(.saveButtonTapped)
                    } label: {
                        Text("Publish")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(store.isValid ? Color.white : Color.gray)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(store.isValid ? Color.ds.accent : Color.gray.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .disabled(!store.isValid)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                
                // Main Content Canvas
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Interactive Category Chips
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(CommunityCategory.allCases) { category in
                                    Button {
                                        DSHaptics.selection()
                                        store.category = category.rawValue
                                    } label: {
                                        Text(category.rawValue)
                                            .font(.system(size: 14, weight: .semibold))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(
                                                store.category == category.rawValue ?
                                                Color.ds.accent : Color.ds.backgroundSecondary
                                            )
                                            .foregroundStyle(
                                                store.category == category.rawValue ?
                                                Color.white : Color.primary
                                            )
                                            .clipShape(Capsule())
                                            .animation(.spring(response: 0.3), value: store.category)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 8)
                        
                        // Dynamic Image Header (If selected)
                        if let data = store.selectedImageData, let uiImage = UIImage(data: data) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 250)
                                    .clipped()
                                    .cornerRadius(24)
                                
                                Button {
                                    withAnimation(.spring()) {
                                        store.selectedPhotoItem = nil
                                        store.selectedImageData = nil
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundStyle(.white)
                                        .frame(width: 32, height: 32)
                                        .background(.ultraThinMaterial)
                                        .environment(\.colorScheme, .dark)
                                        .clipShape(Circle())
                                }
                                .padding(16)
                            }
                            .padding(.horizontal)
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            // Massive Title Input
                            TextField("Give your story a title...", text: $store.title)
                                .font(.system(size: 32, weight: .heavy, design: .rounded))
                                .foregroundStyle(Color.ds.textPrimary)
                                .submitLabel(.next)
                            
                            // Immersive Body Input
                            TextField("Take a deep breath and share what's on your mind. This is a safe space...", text: $store.content, axis: .vertical)
                                .font(.system(size: 18, weight: .regular))
                                .lineSpacing(6)
                                .foregroundStyle(Color.ds.textPrimary.opacity(0.9))
                                .focused($isContentFocused)
                                .frame(minHeight: 200, alignment: .topLeading)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 60)
                }
                .scrollDismissesKeyboard(.interactively)
                
                // Bottom Interactive Toolbar
                VStack(spacing: 0) {
                    Divider()
                        .opacity(0.5)
                    HStack {
                        PhotosPicker(selection: $store.selectedPhotoItem, matching: .images) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 20))
                                Text("Add Photo")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(store.selectedImageData == nil ? Color.ds.accent : Color.gray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.ds.accent.opacity(0.1))
                            .clipShape(Capsule())
                        }
                        .disabled(store.selectedImageData != nil)
                        
                        Spacer()
                        
                        if isContentFocused {
                            Button {
                                DSHaptics.light()
                                isContentFocused = false
                            } label: {
                                Image(systemName: "keyboard.chevron.compact.down")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(8)
                                    .background(Color.ds.backgroundSecondary)
                                    .clipShape(Circle())
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color.ds.backgroundPrimary)
                }
            }
            .background(Color.ds.backgroundPrimary.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar) // We are using a custom header
            .overlay {
                if store.isSaving {
                    ZStack {
                        Color.black.opacity(0.4).ignoresSafeArea()
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Sharing your journey...")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(40)
                        .background(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    isContentFocused = true
                }
            }
        }
    }
}
