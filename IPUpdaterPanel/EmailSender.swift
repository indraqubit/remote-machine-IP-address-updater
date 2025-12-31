import Foundation

/// Minimal email sender for the Panel to test email configuration
class EmailSender {
    private let apiKey: String
    private let apiURL = URL(string: "https://api.resend.com/emails")!
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendTestEmail(
        to recipient: String,
        ssid: String,
        ip: String,
        metadata: Config.Metadata?
    ) async throws {
        // Prepare email payload
        var payload: [String: Any] = [
            "from": "IP Updater <noreply@resend.dev>",
            "to": [recipient],
            "subject": "Test Email: IP Updater Configuration",
            "html": generateTestEmailHTML(ssid: ssid, ip: ip, metadata: metadata)
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        
        // Create request
        var request = URLRequest(url: apiURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Send request
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "EmailError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            throw NSError(domain: "EmailError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode)"])
        }
    }
    
    private func generateTestEmailHTML(ssid: String, ip: String, metadata: Config.Metadata?) -> String {
        var html = """
        <html>
        <body style="font-family: Arial, sans-serif;">
        <h2>Test Email - IP Updater Configuration</h2>
        <p>This is a test email to verify your IP Updater configuration is working correctly.</p>
        <hr>
        <h3>Network Information (Test)</h3>
        <p><strong>SSID:</strong> \(ssid)</p>
        <p><strong>IP Address:</strong> \(ip)</p>
        """
        
        if let label = metadata?.label {
            html += "<p><strong>Label:</strong> \(label)</p>"
        }
        
        if let notes = metadata?.notes {
            html += "<p><strong>Notes:</strong> \(notes)</p>"
        }
        
        html += """
        <hr>
        <p><small>Sent at \(ISO8601DateFormatter().string(from: Date()))</small></p>
        <p><small>This is a test email and does not indicate an actual network change.</small></p>
        </body>
        </html>
        """
        
        return html
    }
}
