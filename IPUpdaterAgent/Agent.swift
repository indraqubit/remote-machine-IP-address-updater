import Foundation

/// Event-driven agent that executes once per trigger.
/// Exits immediately if:
/// - Agent is disabled
/// - Network detection fails
/// - No change detected
/// - Email send fails
/// 
/// No retries. No loops. Silent failure.
class Agent {
    private let configManager: ConfigManaging
    private let stateManager: StateManaging
    private let networkDetector: NetworkDetecting
    private let emailSender: EmailSending
    private let historyManager: StateHistoryManaging
    
    init(
        configManager: ConfigManaging,
        stateManager: StateManaging,
        networkDetector: NetworkDetecting,
        emailSender: EmailSending,
        historyManager: StateHistoryManaging
    ) {
        self.configManager = configManager
        self.stateManager = stateManager
        self.networkDetector = networkDetector
        self.emailSender = emailSender
        self.historyManager = historyManager
    }
    
    func run() throws {
        // Read config
        let config: Config
        do {
            config = try configManager.read()
        } catch ConfigError.disabled {
            // Silent exit when disabled
            return
        } catch {
            throw error
        }
        
        // Detect Wi-Fi SSID
        let ssid: String
        do {
            ssid = try networkDetector.detectWiFiSSID()
        } catch {
            // Silent exit on network error
            return
        }
        
        // Detect private IPv4
        let ip: String
        do {
            ip = try networkDetector.detectPrivateIPv4()
        } catch {
            // Silent exit on network error
            return
        }
        
        // Read previous state
        let previousState = try stateManager.read()
        
        // Check if change detected
        var reason: String = "unknown"
        var changeDetected = false
        
        if let previous = previousState {
            let ssidChanged = previous.ssid != ssid
            let ipChanged = previous.ip != ip
            
            if ssidChanged && ipChanged {
                reason = "both_change"
                changeDetected = true
            } else if ssidChanged {
                reason = "ssid_change"
                changeDetected = true
            } else if ipChanged {
                reason = "ip_change"
                changeDetected = true
            } else {
                // No change - exit silently
                return
            }
        } else {
            reason = "first_run"
            changeDetected = true
        }
        
        // Send email
        var emailSent = false
        do {
            try emailSender.send(config: config, ssid: ssid, ip: ip)
            emailSent = true
        } catch {
            // Silent failure - exit without updating state
            // Still record attempt in history
            let timestamp = ISO8601DateFormatter().string(from: Date())
            let entry = StateHistory.HistoryEntry(
                timestamp: timestamp,
                ssid: ssid,
                ip: ip,
                emailSent: false,
                reason: reason
            )
            try? historyManager.append(entry)
            return
        }
        
        // Write state only after successful email
        let newState = State(
            ssid: ssid,
            ip: ip,
            lastChanged: ISO8601DateFormatter().string(from: Date())
        )
        try stateManager.write(newState)
        
        // Record success in history
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let entry = StateHistory.HistoryEntry(
            timestamp: timestamp,
            ssid: ssid,
            ip: ip,
            emailSent: emailSent,
            reason: reason
        )
        try? historyManager.append(entry)
    }
}

