import Foundation

class PanelViewModel: ObservableObject {
    @Published var enabled: Bool = false
    @Published var emailsText: String = ""  // Multi-line text for display
    @Published var label: String = ""
    @Published var notes: String = ""
    @Published var apiKey: String = ""
    @Published var emailError: String?
    @Published var lastSSID: String?
    @Published var lastIP: String?
    @Published var lastChanged: String?
    @Published var testEmailStatus: String?  // For test email feedback
    
    private let configManager: PanelConfigManager
    private let keychainManager: KeychainManager
    private let launchctlManager: LaunchctlManager
    
    private var originalConfig: Config?
    
    init(
        configManager: PanelConfigManager,
        keychainManager: KeychainManager,
        launchctlManager: LaunchctlManager
    ) {
        self.configManager = configManager
        self.keychainManager = keychainManager
        self.launchctlManager = launchctlManager
    }
    
    /// Parses emails from multi-line text, filters empty lines and validates.
    private var parsedEmails: [String] {
        emailsText
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }
    
    /// Validates parsed emails.
    var isEmailValid: Bool {
        let emails = parsedEmails
        guard !emails.isEmpty else { return false }
        return emails.allSatisfy { isValidEmail($0) }
    }
    
    /// Email validation using basic RFC 5322 checks.
    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            // Fallback to simple check if regex fails
            return email.contains("@") && email.contains(".")
        }
        let range = NSRange(email.startIndex..<email.endIndex, in: email)
        return regex.firstMatch(in: email, range: range) != nil
    }
    
    func load() {
        if let config = configManager.read() {
            enabled = config.enabled
            // Load emails from v2 or v1 format
            emailsText = config.allEmails.joined(separator: "\n")
            label = config.metadata?.label ?? ""
            notes = config.metadata?.notes ?? ""
            
            // Try to load API key from keychain
            do {
                apiKey = try keychainManager.retrieve(
                    service: config.keychain.service,
                    account: config.keychain.account
                )
            } catch {
                apiKey = ""
            }
            
            originalConfig = config
        } else {
            // Defaults
            enabled = false
            emailsText = ""
            label = ""
            notes = ""
            apiKey = ""
            originalConfig = nil
        }
        
        // Load last known state
        loadLastState()
    }
    
    private func loadLastState() {
        let stateURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("IPUpdater")
            .appendingPathComponent("state.json")

        guard FileManager.default.fileExists(atPath: stateURL.path),
              let data = try? Data(contentsOf: stateURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            lastSSID = nil
            lastIP = nil
            lastChanged = nil
            return
        }

        // Agent state only contains IP (SSID removed per contract.md v1.1)
        // Panel can detect SSID separately for UI display if needed
        lastSSID = nil  // No longer stored in state.json
        lastIP = json["ip"] as? String

        if let timestamp = json["lastChanged"] as? String {
            // Format timestamp for display (e.g., "2025-12-31 13:45:00")
            if let date = ISO8601DateFormatter().date(from: timestamp) {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                lastChanged = formatter.string(from: date)
            } else {
                lastChanged = timestamp
            }
        }
    }
    
    @discardableResult
    func save() -> Bool {
        // Validate email
        guard isEmailValid else {
            emailError = "Invalid email address"
            return false
        }
        
        // Validate API key
        guard !apiKey.isEmpty else {
            emailError = "API key is required"
            return false
        }
        
        emailError = nil
        
        // Store API key in keychain
        let service = keychainManager.getDefaultService()
        let account = keychainManager.getDefaultAccount()
        
        do {
            try keychainManager.store(apiKey: apiKey, service: service, account: account)
        } catch {
            emailError = "Failed to store API key"
            return false
        }
        
        // Create metadata if needed
        let metadata: Config.Metadata?
        if !label.isEmpty || !notes.isEmpty {
            metadata = Config.Metadata(label: label.isEmpty ? nil : label, notes: notes.isEmpty ? nil : notes)
        } else {
            metadata = nil
        }
        
        // Create config (v2 format with emails array)
        let config = Config(
            version: 2,
            enabled: enabled,
            email: nil,  // v2 uses emails array
            emails: parsedEmails,
            metadata: metadata,
            keychain: Config.KeychainRef(service: service, account: account)
        )
        
        // Write config
        do {
            try configManager.write(config)
        } catch {
            emailError = "Failed to save configuration"
            return false
        }
        
        // Update launchctl
        do {
            if enabled {
                try launchctlManager.enable()
            } else {
                try launchctlManager.disable()
            }
        } catch {
            emailError = "Failed to update agent"
            return false
        }
        
        originalConfig = config
        return true
    }
    
    func cancel() {
        // Reload original state
        load()
    }
    
    func sendTestEmail() {
        // Validate first
        guard isEmailValid else {
            testEmailStatus = "Invalid email address"
            return
        }
        
        guard !apiKey.isEmpty else {
            testEmailStatus = "API key is required"
            return
        }
        
        testEmailStatus = nil
        
        // Detect current network (fallback to test values if detection fails)
        let networkDetector = NetworkDetector()
        var ssid = "TEST_NETWORK"
        var ip = "192.168.1.100"
        var detectionError = ""
        
        do {
            ssid = try networkDetector.detectWiFiSSID()
        } catch {
            detectionError = "SSID detection failed: \(error)"
        }
        
        do {
            ip = try networkDetector.detectPrivateIPv4()
        } catch {
            if !detectionError.isEmpty {
                detectionError += "; "
            }
            detectionError += "IP detection failed: \(error)"
        }
        
        // Create test email sender
        let emailSender = EmailSender(apiKey: apiKey)
        let emails = parsedEmails
        
        Task {
            do {
                for email in emails {
                    _ = try await emailSender.sendTestEmail(
                        to: email,
                        ssid: ssid,
                        ip: ip,
                        metadata: Config.Metadata(label: label.isEmpty ? nil : label, notes: notes.isEmpty ? nil : notes)
                    )
                }
                DispatchQueue.main.async {
                    var message = "✓ Test email sent successfully!\n"
                    message += "SSID: \(ssid)\n"
                    message += "IP: \(ip)"
                    
                    if !detectionError.isEmpty {
                        message += "\n\n⚠️ Detection issue:\n\(detectionError)"
                    }
                    
                    self.testEmailStatus = message
                }
            } catch {
                DispatchQueue.main.async {
                    self.testEmailStatus = "✗ Failed to send: \(error.localizedDescription)"
                }
            }
        }
    }
}

