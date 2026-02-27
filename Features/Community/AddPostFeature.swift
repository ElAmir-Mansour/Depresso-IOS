// In Features/Community/AddPostFeature.swift
import Foundation
import ComposableArchitecture
import SwiftData
import PhotosUI
import SwiftUI

@Reducer
struct AddPostFeature {
    @ObservableState
    struct State: Equatable {
        var title: String = ""
        var content: String = ""
        var category: String = "General"
        var isSaving: Bool = false
        
        var selectedPhotoItem: PhotosPickerItem? = nil
        var selectedImageData: Data? = nil
        
        var isValid: Bool {
            !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case cancelButtonTapped
        case saveButtonTapped
        case delegate(Delegate)
        case imageDataLoaded(Result<Data?, Error>)

        enum Delegate {
            case savePost(PostDraft)
        }
    }
    
    struct PostDraft: Equatable {
        let title: String
        let content: String
        let category: String
        let imageData: Data?
    }

    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                return .run { _ in await self.dismiss() }

            case .saveButtonTapped:
                guard state.isValid else { return .none }
                state.isSaving = true

                let draft = PostDraft(
                    title: state.title,
                    content: state.content,
                    category: state.category,
                    imageData: state.selectedImageData
                )
                
                return .run { send in
                    await send(.delegate(.savePost(draft)))
                    await self.dismiss()
                }

            case .binding(\.selectedPhotoItem):
                guard let newItem = state.selectedPhotoItem else {
                    state.selectedImageData = nil
                    return .none
                }
                return .run { send in
                    let result = await Result { try await newItem.loadTransferable(type: Data.self) }
                    await send(.imageDataLoaded(result))
                }
                
            case .imageDataLoaded(.success(let data)):
                state.selectedImageData = data
                return .none
                
            case .imageDataLoaded(.failure(let error)):
                print("❌ Failed to load image data: \(error)")
                state.selectedImageData = nil
                return .none

            case .binding:
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
