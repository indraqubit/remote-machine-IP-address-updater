import XCTest
@testable import IPUpdaterPanel

final class PanelBehaviorTests: XCTestCase {
    
    var configManager: PanelConfigManager!
    var keychainManager: KeychainManager!
    var launchctlManager: LaunchctlManager!
    var panel: PanelViewModel!
    
    var configURL: URL!
    
    override func setUp() {
        super.setUp()
        
        let tempDir = FileManager.default.temporaryDirectory
        configURL = tempDir.appendingPathComponent("config.json")
        
        try? FileManager.default.removeItem(at: configURL)
        
        configManager = PanelConfigManager(configURL: configURL)
        keychainManager = KeychainManager()
        launchctlManager = LaunchctlManager()
        panel = PanelViewModel(
            configManager: configManager,
            keychainManager: keychainManager,
            launchctlManager: launchctlManager
        )
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: configURL)
        super.tearDown()
    }
    
    // MARK: - Initial Launch Tests
    
    func testPanelCreatesDefaultsWhenConfigMissing() {
        XCTAssertFalse(FileManager.default.fileExists(atPath: configURL.path))
        
        panel.load()
        
        XCTAssertEqual(panel.enabled, false)
        XCTAssertEqual(panel.emailsText, "")
    }
    
    func testPanelLoadsExistingConfig() throws {
        let config = Config(
            version: 2,
            enabled: true,
            email: nil,
            emails: ["test@example.com"],
            metadata: Config.Metadata(label: "Test", notes: "Notes"),
            keychain: Config.KeychainRef(service: "test", account: "test")
        )
        try writeConfig(config)
        
        panel.load()
        
        XCTAssertEqual(panel.enabled, true)
        XCTAssertEqual(panel.emailsText, "test@example.com")
        XCTAssertEqual(panel.label, "Test")
        XCTAssertEqual(panel.notes, "Notes")
    }
    
    func testPanelOverwritesCorruptConfig() throws {
        try "invalid json".write(to: configURL, atomically: true, encoding: .utf8)
        
        panel.load()
        
        XCTAssertEqual(panel.enabled, false)
    }
    
    // MARK: - Enable/Disable Toggle Tests
    
    func testPanelUpdatesEnabledState() {
        panel.load()
        XCTAssertEqual(panel.enabled, false)
        
        panel.enabled = true
        XCTAssertEqual(panel.enabled, true)
        
        panel.enabled = false
        XCTAssertEqual(panel.enabled, false)
    }
    
    func testPanelDisablesAgentOnSaveWhenToggledOff() throws {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test@example.com"
        panel.apiKey = "test-key"
        
        panel.save()
        
        XCTAssertTrue(launchctlManager.disableCalled)
    }
    
    func testPanelEnablesAgentOnSaveWhenToggledOn() throws {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test@example.com"
        panel.apiKey = "test-key"
        
        panel.save()
        
        XCTAssertTrue(launchctlManager.enableCalled)
    }
    
    // MARK: - Email Input Tests
    
    func testPanelValidatesEmailFormat() {
        panel.load()
        
        panel.emailsText = ""
        XCTAssertFalse(panel.isEmailValid)
        
        panel.emailsText = "invalid"
        XCTAssertFalse(panel.isEmailValid)
        
        panel.emailsText = "test@example.com"
        XCTAssertTrue(panel.isEmailValid)
    }
    
    func testPanelValidatesMultipleEmails() {
        panel.load()
        
        panel.emailsText = "test1@example.com\ntest2@example.com"
        XCTAssertTrue(panel.isEmailValid)
        
        panel.emailsText = "test1@example.com\ninvalid\ntest2@example.com"
        XCTAssertFalse(panel.isEmailValid)
    }
    
    func testPanelBlocksSaveWithInvalidEmail() {
        panel.load()
        panel.enabled = true
        panel.emailsText = "invalid"
        panel.apiKey = "test-key"
        
        let result = panel.save()
        
        XCTAssertFalse(result)
    }
    
    // MARK: - Metadata Tests
    
    func testPanelSavesEmptyMetadata() throws {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test@example.com"
        panel.apiKey = "test-key"
        panel.label = ""
        panel.notes = ""
        
        panel.save()
        
        let config = try readConfig()
        XCTAssertNil(config.metadata)
    }
    
    func testPanelSavesMetadata() throws {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test@example.com"
        panel.apiKey = "test-key"
        panel.label = "Test Label"
        panel.notes = "Test Notes"
        
        panel.save()
        
        let config = try readConfig()
        XCTAssertEqual(config.metadata?.label, "Test Label")
        XCTAssertEqual(config.metadata?.notes, "Test Notes")
    }
    
    // MARK: - API Key Tests
    
    func testPanelStoresAPIKeyInKeychain() throws {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test@example.com"
        panel.apiKey = "secret-api-key"
        
        panel.save()
        
        XCTAssertTrue(keychainManager.storeCalled)
        XCTAssertEqual(keychainManager.lastKey, "secret-api-key")
    }
    
    func testPanelBlocksSaveWithEmptyAPIKey() {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test@example.com"
        panel.apiKey = ""
        
        let result = panel.save()
        
        XCTAssertFalse(result)
    }
    
    func testPanelDoesNotWriteSecretToConfig() throws {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test@example.com"
        panel.apiKey = "secret-key"
        
        panel.save()
        
        let config = try readConfig()
        let configString = try String(contentsOf: configURL)
        
        XCTAssertFalse(configString.contains("secret-key"))
    }
    
    // MARK: - Save Semantics Tests
    
    func testPanelWritesConfigAtomically() throws {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test@example.com"
        panel.apiKey = "test-key"
        
        panel.save()
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: configURL.path))
        let config = try readConfig()
        XCTAssertEqual(config.emails, ["test@example.com"])
    }
    
    func testPanelSavesMultipleEmails() throws {
        panel.load()
        panel.enabled = true
        panel.emailsText = "test1@example.com\ntest2@example.com"
        panel.apiKey = "test-key"
        
        panel.save()
        
        let config = try readConfig()
        XCTAssertEqual(config.emails, ["test1@example.com", "test2@example.com"])
        XCTAssertEqual(config.version, 2)
    }
    
    // MARK: - Cancel Tests
    
    func testPanelDiscardsChangesOnCancel() throws {
        let config = Config(
            version: 2,
            enabled: false,
            email: nil,
            emails: ["original@example.com"],
            metadata: nil,
            keychain: Config.KeychainRef(service: "test", account: "test")
        )
        try writeConfig(config)
        
        panel.load()
        panel.emailsText = "changed@example.com"
        
        panel.cancel()
        
        panel.load()
        XCTAssertEqual(panel.emailsText, "original@example.com")
    }
    
    // MARK: - Helper Methods
    
    private func writeConfig(_ config: Config) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }
    
    private func readConfig() throws -> Config {
        let data = try Data(contentsOf: configURL)
        return try JSONDecoder().decode(Config.self, from: data)
    }
}

