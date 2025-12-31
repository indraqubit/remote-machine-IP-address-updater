import Foundation

/// Protocol for reading configuration.
/// Allows dependency injection and testing without file I/O.
protocol ConfigManaging {
    /// Reads and validates the configuration.
    /// - Throws: ConfigError if config is missing, invalid, or disabled
    func read() throws -> Config
}

// MARK: - Real Implementation

/// Production implementation using file I/O.
class ConfigManager: ConfigManaging {
    private let configURL: URL
    
    init(configURL: URL) {
        self.configURL = configURL
    }
    
    func read() throws -> Config {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw ConfigError.missing
        }
        
        // Read file
        let data = try Data(contentsOf: configURL)
        
        // Decode JSON
        let config = try JSONDecoder().decode(Config.self, from: data)
        
        // Validate version (support v1 and v2)
        guard config.version == 1 || config.version == 2 else {
            throw ConfigError.unknownVersion
        }
        
        // Check if disabled
        guard config.enabled else {
            throw ConfigError.disabled
        }
        
        // Validate email(s) - handle both v1 and v2
        if config.version == 2 {
            // v2: require emails array
            guard let emails = config.emails, !emails.isEmpty else {
                throw ConfigError.missingEmail
            }
        } else {
            // v1: require email string (deprecated but supported)
            guard let email = config.email, !email.isEmpty else {
                throw ConfigError.missingEmail
            }
        }
        
        // Validate keychain reference
        guard !config.keychain.service.isEmpty && !config.keychain.account.isEmpty else {
            throw ConfigError.invalidKeychain
        }
        
        return config
    }
}

// MARK: - Test Implementation

#if DEBUG || TESTING
/// Test double for ConfigManaging.
class MockConfigManager: ConfigManaging {
    var configToReturn: Config?
    var errorToThrow: ConfigError?
    
    func read() throws -> Config {
        if let error = errorToThrow {
            throw error
        }
        guard let config = configToReturn else {
            throw ConfigError.missing
        }
        return config
    }
}
#endif

enum ConfigError: Error {
    case missing
    case invalid
    case unknownVersion
    case missingEmail
    case invalidKeychain
    case disabled
}
