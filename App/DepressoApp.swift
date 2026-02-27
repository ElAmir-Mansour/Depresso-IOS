// In App/DepressoApp.swift
import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct DepressoApp: App {

    private static var container: ModelContainer = {
        let schema = Schema([
            ChatMessage.self,
            WellnessTask.self,
            CommunityPost.self,
            DailyAssessment.self,
            JournalEntry.self,
            ResearchEntry.self,
            Achievement.self
        ])
        
        // Use a persistent configuration
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("❌ SwiftData Load Error: \(error)")
            // Fallback to in-memory if persistent store fails (common during development schema changes)
            // This prevents the crash but won't save data between launches until the app is reinstalled
            do {
                let inMemoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [inMemoryConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    static let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    } withDependencies: {
        $0.modelContext = ModelContextBox(container.mainContext)
    }

    init() {
        // Setup notification categories
        NotificationClient.setupNotificationCategories()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: DepressoApp.store)
        }
      .modelContainer(Self.container)
    }
}
