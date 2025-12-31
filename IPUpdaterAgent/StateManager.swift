import Foundation

class StateManager {
    private let stateURL: URL
    
    init(stateURL: URL) {
        self.stateURL = stateURL
    }
    
    func read() throws -> State? {
        guard FileManager.default.fileExists(atPath: stateURL.path) else {
            return nil
        }
        
        let data = try Data(contentsOf: stateURL)
        
        do {
            return try JSONDecoder().decode(State.self, from: data)
        } catch {
            // Corrupt state - return nil (will be overwritten on next successful email)
            return nil
        }
    }
    
    func write(_ state: State) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(state)
        
        // Ensure directory exists
        let directory = stateURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        
        // Atomic write
        try data.write(to: stateURL, options: .atomic)
    }
}

