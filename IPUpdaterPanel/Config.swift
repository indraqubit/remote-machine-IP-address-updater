import Foundation

struct Config: Codable {
    let version: Int
    let enabled: Bool
    let email: String
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
}

