// Features/Support/SupportFeature.swift
import Foundation
import ComposableArchitecture
import SwiftUI

@Reducer
struct SupportFeature {
    @ObservableState
    struct State: Equatable {
        var resources: [SupportResource] = [
            .init(title: "Shezlong",
                  description: "Online platform to find and book sessions with licensed therapists in Egypt.",
                  url: URL(string: "https://www.shezlong.com/en")!,
                  iconName: "magnifyingglass"),
            .init(title: "O7 Therapy",
                  description: "Another platform connecting users with mental health professionals in the region.",
                  url: URL(string: "https://o7therapy.com/")!,
                  iconName: "person.crop.circle.badge.questionmark"),
            .init(title: "GSMHAT Website",
                  description: "Official information from the General Secretariat of Mental Health.",
                  url: URL(string: "http://www.gsmhat.gov.eg")!,
                  iconName: "network"),
            .init(title: "World Health Organization (WHO) - Depression",
                  description: "Global information on understanding depression.",
                  url: URL(string: "https://www.who.int/news-room/fact-sheets/detail/depression")!,
                  iconName: "book.closed"),
            .init(title: "Building Better Mental Health",
                  description: "General tips for improving mental wellness (HelpGuide).",
                  url: URL(string: "https://www.helpguide.org/articles/healthy-living/building-better-mental-health.htm")!,
                  iconName: "heart.text.square")
        ]
        
        var hotlines: [Hotline] = [
             .init(name: "Ministry of Health Mental Health Hotline", phoneNumber: "16328", description: "General Secretariat of Mental Health and Addiction Treatment (GSMHAT) hotline.", iconName: "phone.fill"),
             .init(name: "Emergency Police", phoneNumber: "122", description: "General emergency number.", iconName: "exclamationmark.bubble.fill"),
             .init(name: "Ambulance", phoneNumber: "123", description: "For medical emergencies.", iconName: "cross.fill")
        ]
        @Presents var destination: Destination.State?
    }
    
    enum Action {
        case settingsButtonTapped
        case destination(PresentationAction<Destination.Action>)
        case delegate(Delegate)
        
        enum Delegate: Equatable {
            case userLoggedOut
            case accountDeleted
        }
    }
    
    @Reducer(state: .equatable)
    enum Destination {
        case settings(SettingsFeature)
    }
    
    var body: some ReducerOf<Self> {
        Reduce<State, Action> { state, action in
            switch action {
            case .settingsButtonTapped:
                state.destination = .settings(SettingsFeature.State())
                return .none
                
            case .destination(.presented(.settings(.delegate(.userLoggedOut)))):
                state.destination = nil
                return .send(.delegate(.userLoggedOut))
                
            case .destination(.presented(.settings(.delegate(.accountDeleted)))):
                state.destination = nil
                return .send(.delegate(.accountDeleted))
                
            case .destination:
                return .none
                
            case .delegate:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}
