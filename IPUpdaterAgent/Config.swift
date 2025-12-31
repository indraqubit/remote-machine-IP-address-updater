import Foundation

struct Config: Codable {
    let version: Int
    let enabled: Bool
    let email: String?  // v1 only (deprecated)
    let emails: [String]?  // v2+ (current)
    let metadata: Metadata?
    let keychain: KeychainRef
    
    struct Metadata: Codable {
        let label: String?
        let notes: String?
    }
    
    struct KeychainRef: Codable {
        let service: String
        let account: String
    }
    
    /// Returns all recipient emails, handling both v1 and v2 formats.
    var allEmails: [String] {
        if let emails = emails, !emails.isEmpty {
            return emails  // v2
        }
        if let email = email, !email.isEmpty {
            return [email]  // v1 fallback
        }
        return []
    }
}

