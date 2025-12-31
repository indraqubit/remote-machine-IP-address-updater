import Foundation

class PanelViewModel: ObservableObject {
    @Published var enabled: Bool = false
    @Published var emailsText: String = ""  // Multi-line text for display
    @Published var label: String = ""
    @Published var notes: String = ""
    @Published var apiKey: String = ""
    @Published var emailError: String?
    
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
    
    /// Simple email validation.
    private func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
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
        let service = keychainManager.defaultService()
        let account = keychainManager.defaultAccount()
        
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
}

