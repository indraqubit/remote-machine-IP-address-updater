import XCTest
@testable import IPUpdaterAgent

final class StateContractTests: XCTestCase {
    
    func testStateDecodesValidJSON() throws {
        let json = """
        {
            "ssid": "MyWiFi",
            "ip": "192.168.1.100",
            "lastChanged": "2024-01-01T12:00:00Z"
        }
        """
        
        let data = json.data(using: .utf8)!
        let state = try JSONDecoder().decode(State.self, from: data)
        
        XCTAssertEqual(state.ssid, "MyWiFi")
        XCTAssertEqual(state.ip, "192.168.1.100")
        XCTAssertEqual(state.lastChanged, "2024-01-01T12:00:00Z")
    }
    
    func testStateEncodesToValidJSON() throws {
        let state = State(
            ssid: "MyWiFi",
            ip: "192.168.1.100",
            lastChanged: "2024-01-01T12:00:00Z"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"ssid\" : \"MyWiFi\""))
        XCTAssertTrue(json.contains("\"ip\" : \"192.168.1.100\""))
        XCTAssertTrue(json.contains("\"lastChanged\" : \"2024-01-01T12:00:00Z\""))
    }
    
    func testStateRequiresAllFields() {
        let json = """
        {
            "ssid": "MyWiFi"
        }
        """
        
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(State.self, from: data))
    }
}

