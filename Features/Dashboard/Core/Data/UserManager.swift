// Features/Dashboard/Core/Data/UserManager.swift
import Foundation

// This manages the user's ID and profile for all API calls
@MainActor
class UserManager: ObservableObject {
    @Published private(set) var userId: String?
    @Published private(set) var userName: String?
    @Published private(set) var userEmail: String?
    
    private let userDefaultsKey = "depresso_user_id"
    private let userNameKey = "depresso_user_name"
    private let userEmailKey = "depresso_user_email"
    
    // Singleton instance
    static let shared = UserManager()
    
    private init() {
        // Load existing data from UserDefaults
        self.userId = UserDefaults.standard.string(forKey: userDefaultsKey)
        self.userName = UserDefaults.standard.string(forKey: userNameKey)
        self.userEmail = UserDefaults.standard.string(forKey: userEmailKey)
    }
    
    func isUserAuthenticated() -> Bool {
        return userId != nil && !(userId?.isEmpty ?? true)
    }
    
    // Register or retrieve user ID
    func ensureUserRegistered() async throws {
        if userId != nil {
            return
        }
        
        let newUserId = try await APIClient.registerUser()
        self.setUserId(newUserId)
        print("✅ User registered with ID: \(newUserId)")
    }
    
    func setUserId(_ id: String) {
        self.userId = id
        UserDefaults.standard.set(id, forKey: userDefaultsKey)
    }
    
    func setUserProfile(name: String?, email: String?) {
        self.userName = name
        self.userEmail = email
        UserDefaults.standard.set(name, forKey: userNameKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
    }
    
    func clearAll() {
        self.userId = nil
        self.userName = nil
        self.userEmail = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
    }
    
    // Get current user ID (throws if not registered)
    func getCurrentUserId() throws -> String {
        guard let id = userId else {
            throw UserError.notRegistered
        }
        return id
    }
}

enum UserError: Error {
    case notRegistered
}
