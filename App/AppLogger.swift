// App/AppLogger.swift
import Foundation
import OSLog

// Centralized Logger for the entire app
enum AppLogger {
    // Define categories for better filtering in Console.app
    enum Category: String {
        case ai = "🤖 AI"
        case health = "❤️ Health"
        case network = "🌍 Network"
        case ui = "📱 UI"
        case database = "💾 Database"
        case general = "ℹ️ General"
    }

    // Underlying OSLog Logger instances
    private static let aiLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Depresso", category: Category.ai.rawValue)
    private static let healthLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Depresso", category: Category.health.rawValue)
    private static let networkLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Depresso", category: Category.network.rawValue)
    private static let uiLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Depresso", category: Category.ui.rawValue)
    private static let dbLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Depresso", category: Category.database.rawValue)
    private static let generalLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Depresso", category: Category.general.rawValue)

    // Helper to get correct logger
    private static func logger(for category: Category) -> Logger {
        switch category {
        case .ai: return aiLogger
        case .health: return healthLogger
        case .network: return networkLogger
        case .ui: return uiLogger
        case .database: return dbLogger
        case .general: return generalLogger
        }
    }

    // MARK: - Public API

    /// Log informational messages (e.g., "View appeared", "Request started")
    static func info(_ message: String, category: Category = .general) {
        logger(for: category).info("\(message, privacy: .public)")
    }

    /// Log debug messages (verbose data, not needed in prod)
    static func debug(_ message: String, category: Category = .general) {
        logger(for: category).debug("\(message, privacy: .public)")
    }

    /// Log warnings (something unexpected happened but app can continue)
    static func warning(_ message: String, category: Category = .general) {
        logger(for: category).warning("⚠️ \(message, privacy: .public)")
    }

    /// Log errors (operations failed)
    /// - Parameters:
    ///   - error: The Error object caught
    ///   - message: Optional context (e.g. "Failed to save user")
    static func error(_ error: Error, message: String = "", category: Category = .general) {
        let errorDescription = message.isEmpty ? error.localizedDescription : "\(message): \(error.localizedDescription)"
        logger(for: category).error("❌ \(errorDescription, privacy: .public)")
        
        // TODO: Hook up Firebase Crashlytics here for non-fatal reporting
        // Crashlytics.crashlytics().record(error: error)
    }
    
    /// Log critical faults (app might crash or state is corrupted)
    static func fault(_ message: String, category: Category = .general) {
        logger(for: category).fault("🔥 \(message, privacy: .public)")
    }
}
