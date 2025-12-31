import Foundation

/// LaunchAgent entry point.
/// Triggered by system events (Wi-Fi change, wake, login).
/// Executes once, makes one decision, exits.
let configURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library")
    .appendingPathComponent("Application Support")
    .appendingPathComponent("IPUpdater")
    .appendingPathComponent("config.json")

let stateURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library")
    .appendingPathComponent("Application Support")
    .appendingPathComponent("IPUpdater")
    .appendingPathComponent("state.json")

let historyURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library")
    .appendingPathComponent("Application Support")
    .appendingPathComponent("IPUpdater")
    .appendingPathComponent("history.json")

let configManager = ConfigManager(configURL: configURL)
let stateManager = StateManager(stateURL: stateURL)
let historyManager = StateHistoryManager(historyURL: historyURL)
let networkDetector = NetworkDetector()
let emailSender = EmailSender()

let agent = Agent(
    configManager: configManager,
    stateManager: stateManager,
    networkDetector: networkDetector,
    emailSender: emailSender,
    historyManager: historyManager
)

do {
    try agent.run()
} catch {
    // Silent exit on error
    exit(1)
}

exit(0)

