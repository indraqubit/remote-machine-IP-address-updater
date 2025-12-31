import XCTest
@testable import IPUpdaterAgent

final class ConfigContractTests: XCTestCase {
    
    // MARK: - Version 2 Tests (Current)
    
    func testV2ConfigDecodesMultipleEmails() throws {
        let json = """
        {
            "version": 2,
            "enabled": true,
            "emails": ["test1@example.com", "test2@example.com"],
            "metadata": {
                "label": "Test",
                "notes": "Notes"
            },
            "keychain": {
                "service": "com.example.service",
                "account": "api-key"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: data)
        
        XCTAssertEqual(config.version, 2)
        XCTAssertEqual(config.emails, ["test1@example.com", "test2@example.com"])
        XCTAssertEqual(config.allEmails, ["test1@example.com", "test2@example.com"])
    }
    
    func testV2ConfigEncodesToValidJSON() throws {
        let config = Config(
            version: 2,
            enabled: true,
            email: nil,
            emails: ["test1@example.com", "test2@example.com"],
            metadata: Config.Metadata(label: "Test", notes: "Notes"),
            keychain: Config.KeychainRef(service: "com.example.service", account: "api-key")
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        let json = String(data: data, encoding: .utf8)!
        
        XCTAssertTrue(json.contains("\"version\" : 2"))
        XCTAssertTrue(json.contains("\"emails\""))
        XCTAssertTrue(json.contains("test1@example.com"))
    }
    
    // MARK: - Version 1 Tests (Backward Compatibility)
    
    func testV1ConfigDecodesValidJSON() throws {
        let json = """
        {
            "version": 1,
            "enabled": true,
            "email": "test@example.com",
            "metadata": {
                "label": "Test",
                "notes": "Notes"
            },
            "keychain": {
                "service": "com.example.service",
                "account": "api-key"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: data)
        
        XCTAssertEqual(config.version, 1)
        XCTAssertEqual(config.email, "test@example.com")
        XCTAssertEqual(config.allEmails, ["test@example.com"])  // Fallback to v1 format
    }
    
    func testV1ConfigDecodesWithoutMetadata() throws {
        let json = """
        {
            "version": 1,
            "enabled": true,
            "email": "test@example.com",
            "keychain": {
                "service": "com.example.service",
                "account": "api-key"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        let config = try JSONDecoder().decode(Config.self, from: data)
        
        XCTAssertNil(config.metadata)
        XCTAssertEqual(config.allEmails, ["test@example.com"])
    }
    
    func testAllEmailsFallsBackToV1() throws {
        let config = Config(
            version: 1,
            enabled: true,
            email: "test@example.com",
            emails: nil,
            metadata: nil,
            keychain: Config.KeychainRef(service: "test", account: "test")
        )
        
        XCTAssertEqual(config.allEmails, ["test@example.com"])
    }
    
    func testAllEmailsPrefersV2() throws {
        let config = Config(
            version: 2,
            enabled: true,
            email: "ignored@example.com",
            emails: ["preferred@example.com"],
            metadata: nil,
            keychain: Config.KeychainRef(service: "test", account: "test")
        )
        
        XCTAssertEqual(config.allEmails, ["preferred@example.com"])
    }
    
    func testConfigRejectsInvalidVersion() {
        let json = """
        {
            "version": "invalid",
            "enabled": true,
            "email": "test@example.com",
            "keychain": {
                "service": "com.example.service",
                "account": "api-key"
            }
        }
        """
        
        let data = json.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(Config.self, from: data))
    }
}

