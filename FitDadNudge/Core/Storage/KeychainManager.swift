import Foundation
import Security

final class KeychainManager {
    private let service = "com.fitdad.nudge"
    private let userIDKey = "userID"
    
    // MARK: - User ID Management
    
    func saveUserID(_ userID: String) {
        save(userID, for: userIDKey)
    }
    
    func getUserID() -> String? {
        load(for: userIDKey)
    }
    
    func deleteUserID() {
        delete(for: userIDKey)
    }
    
    // MARK: - Generic Keychain Operations
    
    private func save(_ value: String, for key: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess && status != errSecDuplicateItem {
            logError("Error saving to keychain: \(status)", category: .auth)
            
            // Handle specific error cases
            if status == errSecInteractionNotAllowed {
                logError("Keychain access denied - device may be locked", category: .auth)
            }
        }
    }
    
    private func load(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        } else if status != errSecItemNotFound {
            // Log non-trivial errors
            if status == errSecInteractionNotAllowed {
                logError("Keychain read denied - device may be locked", category: .auth)
            } else {
                logError("Error reading from keychain: \(status)", category: .auth)
            }
        }
        
        return nil
    }
    
    private func delete(for key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
} 