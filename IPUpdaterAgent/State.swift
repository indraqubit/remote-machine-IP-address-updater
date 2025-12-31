import Foundation

struct State: Codable {
    let ssid: String
    let ip: String
    let lastChanged: String // ISO-8601 format
}

