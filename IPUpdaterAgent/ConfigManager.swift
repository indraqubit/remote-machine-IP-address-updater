import Foundation

class ConfigManager {
    private let configURL: URL
    
    init(configURL: URL) {
        self.configURL = configURL
    }
    
    func read() throws -> Config {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            throw ConfigError.missing
        }
        
        let data = try Data(contentsOf: configURL)
        
        do {
            let config = try JSONDecoder().decode(Config.self, from: data)
            
            // Validate version
            guard config.version == 1 else {
                throw ConfigError.unknownVersion(config.version)
            }
            
            // Validate enabled
            guard config.enabled else {
                throw ConfigError.disabled
            }
            
            // Validate email
            guard !config.email.isEmpty else {
                throw ConfigError.invalidEmail
            }
            
            return config
        } catch let error as DecodingError {
            throw ConfigError.invalidFormat(error)
        } catch {
            throw ConfigError.invalidFormat(error)
        }
    }
}

enum ConfigError: Error {
    case missing
    case invalidFormat(Error)
    case unknownVersion(Int)
    case disabled
    case invalidEmail
}

