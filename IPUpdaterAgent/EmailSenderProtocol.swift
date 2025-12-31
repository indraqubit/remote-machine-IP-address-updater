import Foundation

/// Protocol for sending emails.
/// Allows dependency injection and testing without network access.
protocol EmailSending {
    /// Sends an email notification with network change details.
    /// - Parameters:
    ///   - config: Configuration containing email address and metadata
    ///   - ssid: The Wi-Fi SSID
    ///   - ip: The private IPv4 address
    /// - Throws: EmailError if sending fails
    func send(config: Config, ssid: String, ip: String) throws
}

// MARK: - Real Implementation

/// Production implementation using URLSession and Resend API.
class EmailSender: EmailSending {
    #if DEBUG || TESTING
    var shouldSucceed: Bool = true
    var sendCalled: Bool = false
    var lastSSID: String?
    var lastIP: String?
    #endif
    
    private let apiURL = URL(string: "https://api.resend.com/emails")!
    
    func send(config: Config, ssid: String, ip: String) throws {
        #if DEBUG || TESTING
        sendCalled = true
        lastSSID = ssid
        lastIP = ip
        
        if !shouldSucceed {
            throw EmailError.sendFailed
        }
        return
        #endif
        
        // Retrieve API key from Keychain
        let apiKey = try retrieveAPIKey(service: config.keychain.service, account: config.keychain.account)
        
        // Get all recipients (v1 or v2)
        let recipients = config.allEmails
        guard !recipients.isEmpty else {
            throw EmailError.sendFailed
        }
        
        // Send to all recipients (all-or-nothing)
        for recipient in recipients {
            // Prepare email payload
            var payload: [String: Any] = [
                "from": "IP Updater <noreply@resend.dev>",
                "to": [recipient],
                "subject": "IP Address Update: \(ssid)",
                "html": generateEmailHTML(config: config, ssid: ssid, ip: ip)
            ]
            
            let jsonData = try JSONSerialization.data(withJSONObject: payload)
            
            // Create request
            var request = URLRequest(url: apiURL)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
            
            // Send synchronously with timeout (agent is short-lived)
            let semaphore = DispatchSemaphore(value: 0)
            var responseError: Error?
            
            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    responseError = error
                } else if let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode < 200 || httpResponse.statusCode >= 300 {
                    responseError = EmailError.sendFailed
                }
                semaphore.signal()
            }
            
            task.resume()
            
            // Wait with 10-second timeout to prevent agent hanging
            let timeout = DispatchTime.now() + .seconds(10)
            let waitResult = semaphore.wait(timeout: timeout)
            
            if waitResult == .timedOut {
                task.cancel()
                throw EmailError.sendFailed
            }
            
            if let error = responseError {
                throw error
            }
        }
    }
    
    private func retrieveAPIKey(service: String, account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            throw EmailError.keychainError
        }
        
        return apiKey
    }
    
    private func generateEmailHTML(config: Config, ssid: String, ip: String) -> String {
        var html = """
        <html>
        <body>
        <h2>IP Address Update</h2>
        <p><strong>SSID:</strong> \(ssid)</p>
        <p><strong>IP Address:</strong> \(ip)</p>
        """
        
        if let label = config.metadata?.label {
            html += "<p><strong>Label:</strong> \(label)</p>"
        }
        
        if let notes = config.metadata?.notes {
            html += "<p><strong>Notes:</strong> \(notes)</p>"
        }
        
        html += """
        <p><small>Sent at \(ISO8601DateFormatter().string(from: Date()))</small></p>
        </body>
        </html>
        """
        
        return html
    }
}

// MARK: - Test Implementation

#if DEBUG || TESTING
/// Test double for EmailSending.
class MockEmailSender: EmailSending {
    var shouldSucceed: Bool = true
    var sendCalled: Bool = false
    var lastConfig: Config?
    var lastSSID: String?
    var lastIP: String?
    var sendError: EmailError?
    
    func send(config: Config, ssid: String, ip: String) throws {
        sendCalled = true
        lastConfig = config
        lastSSID = ssid
        lastIP = ip
        
        if let error = sendError {
            throw error
        }
        
        if !shouldSucceed {
            throw EmailError.sendFailed
        }
    }
}
#endif

enum EmailError: Error {
    case keychainError
    case sendFailed
}
