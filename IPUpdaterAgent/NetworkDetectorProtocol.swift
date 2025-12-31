import Foundation
import SystemConfiguration

/// Protocol for Wi-Fi and network detection.
/// Allows dependency injection and testing without system access.
protocol NetworkDetecting {
    /// Detects the current Wi-Fi SSID.
    /// - Throws: NetworkError if detection fails
    func detectWiFiSSID() throws -> String
    
    /// Detects the current private IPv4 address.
    /// - Throws: NetworkError if detection fails
    func detectPrivateIPv4() throws -> String
}

// MARK: - Real Implementation

/// Production implementation using SystemConfiguration framework.
class NetworkDetector: NetworkDetecting {
    #if DEBUG || TESTING
    var mockSSID: String?
    var mockIP: String?
    #endif
    
    func detectWiFiSSID() throws -> String {
        #if DEBUG || TESTING
        if let mockSSID = mockSSID {
            return mockSSID
        }
        #endif
        
        // Use SystemConfiguration to get current network SSID
        guard let store = SCDynamicStoreCreate(kCFAllocatorDefault, "com.ipupdater.agent" as CFString, nil, nil) else {
            throw NetworkError.noInterfaces
        }
        // Note: Swift auto-manages CF object lifetime
        
        let patterns = [
            "State:/Network/Interface/[^/]+/IPv4" as CFString,
            "State:/Network/Interface/[^/]+/AirPort" as CFString
        ] as CFArray
        
        guard let dict = SCDynamicStoreCopyMultiple(store, nil, patterns) else {
            throw NetworkError.noWiFi
        }
        
        // Check AirPort interfaces
        for (_, value) in dict as NSDictionary {
            if let networkInfo = value as? NSDictionary {
                if let ssid = networkInfo["SSID"] as? String {
                    return ssid
                }
            }
        }
        
        throw NetworkError.noWiFi
    }
    
    func detectPrivateIPv4() throws -> String {
        #if DEBUG || TESTING
        if let mockIP = mockIP {
            return mockIP
        }
        #endif
        
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else {
            throw NetworkError.noInterfaces
        }
        
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee,
                  interface.ifa_addr != nil else {
                continue
            }
            
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily != UInt8(AF_INET) {
                continue
            }
            
            // Check if it's Wi-Fi (en0)
            let name = String(cString: interface.ifa_name)
            if name != "en0" {
                continue
            }
            
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            let result = getnameinfo(
                interface.ifa_addr,
                socklen_t(interface.ifa_addr.pointee.sa_len),
                &hostname,
                socklen_t(hostname.count),
                nil,
                0,
                NI_NUMERICHOST
            )
            
            guard result == 0 else {
                continue
            }
            
            let ip = String(cString: hostname)
            
            // Validate RFC1918
            guard isValidPrivateIP(ip) else {
                continue
            }
            
            address = ip
            break
        }
        
        guard let ip = address else {
            throw NetworkError.noPrivateIP
        }
        
        return ip
    }
    
    private func isValidPrivateIP(_ ip: String) -> Bool {
        // Ignore loopback
        if ip == "127.0.0.1" {
            return false
        }
        
        // Ignore link-local
        if ip.hasPrefix("169.254.") {
            return false
        }
        
        // RFC1918: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
        let parts = ip.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else {
            return false
        }
        
        let (a, b, c, d) = (parts[0], parts[1], parts[2], parts[3])
        
        // 10.0.0.0/8
        if a == 10 {
            return true
        }
        
        // 172.16.0.0/12
        if a == 172 && b >= 16 && b <= 31 {
            return true
        }
        
        // 192.168.0.0/16
        if a == 192 && b == 168 {
            return true
        }
        
        return false
    }
}

// MARK: - Test Implementation

#if DEBUG || TESTING
/// Test double for NetworkDetecting.
class MockNetworkDetector: NetworkDetecting {
    var ssidToReturn: String?
    var ipToReturn: String?
    var ssidError: NetworkError?
    var ipError: NetworkError?
    
    func detectWiFiSSID() throws -> String {
        if let error = ssidError {
            throw error
        }
        guard let ssid = ssidToReturn else {
            throw NetworkError.noWiFi
        }
        return ssid
    }
    
    func detectPrivateIPv4() throws -> String {
        if let error = ipError {
            throw error
        }
        guard let ip = ipToReturn else {
            throw NetworkError.noPrivateIP
        }
        return ip
    }
}
#endif

enum NetworkError: Error {
    case noInterfaces
    case noWiFi
    case noPrivateIP
}
