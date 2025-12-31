import Foundation

class LaunchctlManager {
    #if DEBUG || TESTING
    var enableCalled: Bool = false
    var disableCalled: Bool = false
    #endif
    
    private let plistLabel = "com.ipupdater.agent"
    
    func enable() throws {
        #if DEBUG || TESTING
        enableCalled = true
        return
        #endif
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["enable", "\(plistLabel)"]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw LaunchctlError.enableFailed
        }
    }
    
    func disable() throws {
        #if DEBUG || TESTING
        disableCalled = true
        return
        #endif
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["disable", "\(plistLabel)"]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw LaunchctlError.disableFailed
        }
    }
}

enum LaunchctlError: Error {
    case enableFailed
    case disableFailed
}

