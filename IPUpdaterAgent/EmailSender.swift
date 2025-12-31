import Foundation

class EmailSender {
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
        
        // Prepare email payload
        var payload: [String: Any] = [
            "from": "IP Updater <noreply@resend.dev>",
            "to": [config.email],
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
        
        // Send synchronously (agent is short-lived)
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
        semaphore.wait()
        
        if let error = responseError {
            throw error
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

enum EmailError: Error {
    case keychainError
    case sendFailed
}

