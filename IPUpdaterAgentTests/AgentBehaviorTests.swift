import XCTest
@testable import IPUpdaterAgent

final class AgentBehaviorTests: XCTestCase {
    
    var configManager: ConfigManager!
    var stateManager: StateManager!
    var networkDetector: NetworkDetector!
    var emailSender: EmailSender!
    var agent: Agent!
    
    var configURL: URL!
    var stateURL: URL!
    
    override func setUp() {
        super.setUp()
        
        let tempDir = FileManager.default.temporaryDirectory
        configURL = tempDir.appendingPathComponent("config.json")
        stateURL = tempDir.appendingPathComponent("state.json")
        
        // Clean up
        try? FileManager.default.removeItem(at: configURL)
        try? FileManager.default.removeItem(at: stateURL)
        
        configManager = ConfigManager(configURL: configURL)
        stateManager = StateManager(stateURL: stateURL)
        networkDetector = NetworkDetector()
        emailSender = EmailSender()
        agent = Agent(
            configManager: configManager,
            stateManager: stateManager,
            networkDetector: networkDetector,
            emailSender: emailSender
        )
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: configURL)
        try? FileManager.default.removeItem(at: stateURL)
        super.tearDown()
    }
    
    // MARK: - Disabled Agent Tests
    
    func testAgentExitsWhenEnabledIsFalse() throws {
        let config = Config(
            version: 1,
            enabled: false,
            email: "test@example.com",
            metadata: nil,
            keychain: Config.KeychainRef(service: "test", account: "test")
        )
        try writeConfig(config)
        
        let expectation = XCTestExpectation(description: "Agent exits")
        expectation.isInverted = true // Should exit immediately, not fulfill
        
        // Agent should exit immediately
        XCTAssertNoThrow(try agent.run())
    }
    
    // MARK: - Missing/Invalid Config Tests
    
    func testAgentExitsWhenConfigMissing() {
        XCTAssertThrowsError(try agent.run())
    }
    
    func testAgentExitsWhenConfigInvalid() throws {
        try "invalid json".write(to: configURL, atomically: true, encoding: .utf8)
        XCTAssertThrowsError(try agent.run())
    }
    
    func testAgentExitsWhenConfigVersionUnknown() throws {
        let config = Config(
            version: 999, // Unknown version
            enabled: true,
            email: "test@example.com",
            metadata: nil,
            keychain: Config.KeychainRef(service: "test", account: "test")
        )
        try writeConfig(config)
        
        XCTAssertThrowsError(try agent.run())
    }
    
    func testAgentExitsWhenEmailEmpty() throws {
        let config = Config(
            version: 1,
            enabled: true,
            email: "", // Empty email
            metadata: nil,
            keychain: Config.KeychainRef(service: "test", account: "test")
        )
        try writeConfig(config)
        
        XCTAssertThrowsError(try agent.run())
    }
    
    // MARK: - First Run Tests
    
    func testAgentSendsEmailOnFirstRun() throws {
        let config = createValidConfig()
        try writeConfig(config)
        
        // Mock network detection
        networkDetector.mockSSID = "TestWiFi"
        networkDetector.mockIP = "192.168.1.100"
        
        // Mock email sender
        emailSender.shouldSucceed = true
        
        // No state file exists
        XCTAssertFalse(FileManager.default.fileExists(atPath: stateURL.path))
        
        try agent.run()
        
        // Email should be sent
        XCTAssertTrue(emailSender.sendCalled)
        XCTAssertEqual(emailSender.lastSSID, "TestWiFi")
        XCTAssertEqual(emailSender.lastIP, "192.168.1.100")
        
        // State should be written
        XCTAssertTrue(FileManager.default.fileExists(atPath: stateURL.path))
    }
    
    func testAgentWritesStateAfterSuccessfulEmail() throws {
        let config = createValidConfig()
        try writeConfig(config)
        
        networkDetector.mockSSID = "TestWiFi"
        networkDetector.mockIP = "192.168.1.100"
        emailSender.shouldSucceed = true
        
        try agent.run()
        
        let state = try stateManager.read()
        XCTAssertEqual(state.ssid, "TestWiFi")
        XCTAssertEqual(state.ip, "192.168.1.100")
    }
    
    func testAgentDoesNotWriteStateWhenEmailFails() throws {
        let config = createValidConfig()
        try writeConfig(config)
        
        networkDetector.mockSSID = "TestWiFi"
        networkDetector.mockIP = "192.168.1.100"
        emailSender.shouldSucceed = false
        
        try? agent.run()
        
        // State should not be written
        XCTAssertFalse(FileManager.default.fileExists(atPath: stateURL.path))
    }
    
    // MARK: - No Change Detected Tests
    
    func testAgentExitsWhenStateUnchanged() throws {
        let config = createValidConfig()
        try writeConfig(config)
        
        // Write existing state
        let existingState = State(
            ssid: "TestWiFi",
            ip: "192.168.1.100",
            lastChanged: ISO8601DateFormatter().string(from: Date())
        )
        try writeState(existingState)
        
        networkDetector.mockSSID = "TestWiFi"
        networkDetector.mockIP = "192.168.1.100"
        
        try agent.run()
        
        // Email should not be sent
        XCTAssertFalse(emailSender.sendCalled)
    }
    
    // MARK: - IP Change Tests
    
    func testAgentSendsEmailWhenIPChanges() throws {
        let config = createValidConfig()
        try writeConfig(config)
        
        let existingState = State(
            ssid: "TestWiFi",
            ip: "192.168.1.100",
            lastChanged: ISO8601DateFormatter().string(from: Date())
        )
        try writeState(existingState)
        
        networkDetector.mockSSID = "TestWiFi"
        networkDetector.mockIP = "192.168.1.200" // IP changed
        emailSender.shouldSucceed = true
        
        try agent.run()
        
        XCTAssertTrue(emailSender.sendCalled)
        XCTAssertEqual(emailSender.lastIP, "192.168.1.200")
    }
    
    // MARK: - SSID Change Tests
    
    func testAgentSendsEmailWhenSSIDChanges() throws {
        let config = createValidConfig()
        try writeConfig(config)
        
        let existingState = State(
            ssid: "OldWiFi",
            ip: "192.168.1.100",
            lastChanged: ISO8601DateFormatter().string(from: Date())
        )
        try writeState(existingState)
        
        networkDetector.mockSSID = "NewWiFi" // SSID changed
        networkDetector.mockIP = "192.168.1.100"
        emailSender.shouldSucceed = true
        
        try agent.run()
        
        XCTAssertTrue(emailSender.sendCalled)
        XCTAssertEqual(emailSender.lastSSID, "NewWiFi")
    }
    
    // MARK: - Helper Methods
    
    private func createValidConfig() -> Config {
        Config(
            version: 2,
            enabled: true,
            email: nil,
            emails: ["test@example.com"],
            metadata: nil,
            keychain: Config.KeychainRef(service: "test", account: "test")
        )
    }
    
    private func writeConfig(_ config: Config) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }
    
    private func writeState(_ state: State) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(state)
        try data.write(to: stateURL, options: .atomic)
    }
}

