import Foundation

class PanelConfigManager {
    private let configURL: URL
    
    init(configURL: URL) {
        self.configURL = configURL
    }
    
    func read() -> Config? {
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: configURL) else {
            return nil
        }
        
        guard let config = try? JSONDecoder().decode(Config.self, from: data),
              config.version == 1 || config.version == 2 else {
            return nil
        }
        
        return config
    }
    
    func write(_ config: Config) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(config)
        
        // Ensure directory exists
        let directory = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        
        // Atomic write
        try data.write(to: configURL, options: .atomic)
    }
    
    static func defaultConfigURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("IPUpdater")
            .appendingPathComponent("config.json")
    }
}

