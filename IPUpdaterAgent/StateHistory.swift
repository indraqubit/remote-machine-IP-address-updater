import Foundation

/// Tracks historical state changes for observability.
/// Stored separately from current state to avoid bloating config.json reads.
struct StateHistory: Codable {
    var entries: [HistoryEntry]
    
    struct HistoryEntry: Codable {
        let timestamp: String // ISO-8601
        let ip: String
        let emailSent: Bool
        let reason: String // "first_run", "ip_change", "email_failed"
    }
    
    init(entries: [HistoryEntry] = []) {
        self.entries = entries
    }
    
    /// Adds a new entry and keeps only the last 100 (to avoid unbounded growth).
    mutating func append(_ entry: HistoryEntry) {
        var newEntries = entries
        newEntries.append(entry)
        self.entries = Array(newEntries.suffix(100))
    }
}

// MARK: - State History Manager

/// Manages persistent state history.
protocol StateHistoryManaging {
    /// Reads the history file, or returns empty if it doesn't exist.
    func read() throws -> StateHistory
    
    /// Appends an entry and writes atomically.
    func append(_ entry: StateHistory.HistoryEntry) throws
}

class StateHistoryManager: StateHistoryManaging {
    private let historyURL: URL
    
    init(historyURL: URL) {
        self.historyURL = historyURL
    }
    
    func read() throws -> StateHistory {
        guard FileManager.default.fileExists(atPath: historyURL.path) else {
            return StateHistory(entries: [])
        }
        
        do {
            let data = try Data(contentsOf: historyURL)
            return try JSONDecoder().decode(StateHistory.self, from: data)
        } catch {
            // Corrupt history is ignored, starting fresh
            return StateHistory(entries: [])
        }
    }
    
    func append(_ entry: StateHistory.HistoryEntry) throws {
        var history = try read()
        history.append(entry)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(history)
        try data.write(to: historyURL, options: .atomic)
    }
}

#if DEBUG || TESTING
/// Test double for StateHistoryManaging.
class MockStateHistoryManager: StateHistoryManaging {
    var historyToReturn = StateHistory(entries: [])
    var appendedEntries: [StateHistory.HistoryEntry] = []
    var appendError: Error?
    
    func read() throws -> StateHistory {
        return historyToReturn
    }
    
    func append(_ entry: StateHistory.HistoryEntry) throws {
        if let error = appendError {
            throw error
        }
        appendedEntries.append(entry)
        historyToReturn.append(entry)
    }
}
#endif
