import Foundation

/// Protocol for managing agent state.
/// Allows dependency injection and testing without file I/O.
protocol StateManaging {
    /// Reads the current state, or nil if never written.
    /// - Throws: StateError if state file is corrupt
    func read() throws -> State?
    
    /// Writes state atomically.
    /// - Throws: StateError if write fails
    func write(_ state: State) throws
}

// MARK: - Real Implementation

/// Production implementation using atomic file I/O.
class StateManager: StateManaging {
    private let stateURL: URL
    
    init(stateURL: URL) {
        self.stateURL = stateURL
    }
    
    func read() throws -> State? {
        // If file doesn't exist, return nil (first run)
        guard FileManager.default.fileExists(atPath: stateURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: stateURL)
            return try JSONDecoder().decode(State.self, from: data)
        } catch {
            // Corrupt state is ignored until next successful send
            // Will be overwritten on next successful email send
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

// MARK: - Test Implementation

#if DEBUG || TESTING
/// Test double for StateManaging.
class MockStateManager: StateManaging {
    var stateToReturn: State?
    var readError: Error?
    var writeError: Error?
    var lastWrittenState: State?
    
    func read() throws -> State? {
        if let error = readError {
            throw error
        }
        return stateToReturn
    }
    
    func write(_ state: State) throws {
        if let error = writeError {
            throw error
        }
        lastWrittenState = state
    }
}
#endif

enum StateError: Error {
    case corrupt
    case writeFailed
}
