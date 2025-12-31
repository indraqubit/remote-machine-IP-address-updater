import Foundation
import Security

class KeychainManager {
    #if DEBUG || TESTING
    var storeCalled: Bool = false
    var lastKey: String?
    #endif
    
    private let defaultService = "com.ipupdater.service"
    private let defaultAccount = "resend-api-key"
    
    func store(apiKey: String, service: String, account: String) throws {
        #if DEBUG || TESTING
        storeCalled = true
        lastKey = apiKey
        return
        #endif
        
        // Delete existing item if present
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: apiKey.data(using: .utf8)!
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed
        }
    }
    
    func retrieve(service: String, account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }
        
        return apiKey
    }
    
    func getDefaultService() -> String {
        return defaultService
    }
    
    func getDefaultAccount() -> String {
        return defaultAccount
    }
}

enum KeychainError: Error {
    case storeFailed
    case notFound
}

