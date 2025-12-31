import Foundation

/// Protocol for deterministic IPv4 detection.
/// 
/// Contract:
/// - Returns private IPv4 (RFC1918) only
/// - en0 interface only (Wi-Fi intent)
/// - No SSID, no interface names, no metadata
/// - Throws if guarantees cannot be met
/// - Safe for headless LaunchAgent
protocol NetworkDetecting {
    /// Detects current private IPv4 address.
    ///
    /// Guarantees:
    /// - IPv4 format (dotted decimal)
    /// - RFC1918 (10.x, 172.16-31.x, 192.168.x)
    /// - Not loopback (127.0.0.1)
    /// - Not link-local (169.254.x.x)
    /// - Interface is UP and RUNNING
    /// - en0 only
    ///
    /// - Throws: NetworkError if any guarantee cannot be met
    func detectPrivateIPv4() throws -> String
}

// MARK: - Production Implementation

/// Real NetworkDetector using system APIs.
/// 
/// - Uses getifaddrs for low-level interface enumeration
/// - Validates RFC1918 before returning
/// - Fails deterministically
class NetworkDetector: NetworkDetecting {
    func detectPrivateIPv4() throws -> String {
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
            
            // Only IPv4
            let addrFamily = interface.ifa_addr.pointee.sa_family
            guard addrFamily == UInt8(AF_INET) else {
                continue
            }
            
            // en0 only (Wi-Fi intent)
            let name = String(cString: interface.ifa_name)
            guard name == "en0" else {
                continue
            }
            
            // Must be UP and RUNNING
            let flags = interface.ifa_flags
            guard (flags & UInt32(IFF_UP)) != 0 && (flags & UInt32(IFF_RUNNING)) != 0 else {
                continue
            }
            
            // Extract address
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
        // Reject loopback
        if ip == "127.0.0.1" {
            return false
        }
        
        // Reject link-local
        if ip.hasPrefix("169.254.") {
            return false
        }
        
        // RFC1918: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
        let parts = ip.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else {
            return false
        }
        
        let (a, b, _, _) = (parts[0], parts[1], parts[2], parts[3])
        
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
/// 
/// Used only in test targets. Production code does not use this.
class MockNetworkDetector: NetworkDetecting {
    var ipToReturn: String?
    var errorToThrow: NetworkError?

    func detectPrivateIPv4() throws -> String {
        if let error = errorToThrow {
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
    case noPrivateIP
}
