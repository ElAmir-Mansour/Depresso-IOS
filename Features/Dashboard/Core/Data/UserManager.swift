// Features/Dashboard/Core/Data/UserManager.swift
import Foundation
import Security

// This manages the user's ID and profile for all API calls
@MainActor
class UserManager: ObservableObject {
    @Published private(set) var userId: String?
    @Published private(set) var userName: String?
    @Published private(set) var userEmail: String?
    @Published private(set) var sessionToken: String?
    
    private let userDefaultsKey = "depresso_user_id"
    private let userNameKey = "depresso_user_name"
    private let userEmailKey = "depresso_user_email"
    private let tokenKeychainKey = "depresso_session_token"
    
    // Singleton instance
    static let shared = UserManager()
    
    private init() {
        // Load existing data from UserDefaults
        self.userId = UserDefaults.standard.string(forKey: userDefaultsKey)
        self.userName = UserDefaults.standard.string(forKey: userNameKey)
        self.userEmail = UserDefaults.standard.string(forKey: userEmailKey)
        // Load token from Keychain
        self.sessionToken = KeychainHelper.retrieve(key: tokenKeychainKey)
        
        print("🔄 UserManager initialized - UserID: \(userId ?? "nil"), Has Token: \(sessionToken != nil)")
    }
    
    func isUserAuthenticated() -> Bool {
        return userId != nil && !(userId?.isEmpty ?? true) && sessionToken != nil
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
        UserDefaults.standard.synchronize() // Force immediate persistence
        print("💾 UserManager: Saved userId '\(id)' to UserDefaults")
    }
    
    func setSessionToken(_ token: String) {
        self.sessionToken = token
        KeychainHelper.save(token, forKey: tokenKeychainKey)
        print("🔐 UserManager: Saved session token to Keychain")
    }
    
    func setUserProfile(name: String?, email: String?) {
        self.userName = name
        self.userEmail = email
        UserDefaults.standard.set(name, forKey: userNameKey)
        UserDefaults.standard.set(email, forKey: userEmailKey)
        UserDefaults.standard.synchronize()
        print("👤 UserManager: Saved profile - Name: '\(name ?? "nil")', Email: '\(email ?? "nil")'")
    }
    
    func clearAll() {
        self.userId = nil
        self.userName = nil
        self.userEmail = nil
        self.sessionToken = nil
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        KeychainHelper.delete(key: tokenKeychainKey)
    }
    
    // Get current user ID (throws if not registered)
    func getCurrentUserId() throws -> String {
        guard let id = userId else {
            throw UserError.notRegistered
        }
        return id
    }
}

// Keychain Helper for secure token storage
class KeychainHelper {
    static func save(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("⚠️ Keychain save failed: \(status)")
        }
    }
    
    static func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    static func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum UserError: Error {
    case notRegistered
}
