import Foundation
import SystemConfiguration

/// Minimal network detector for Panel (mirrors Agent's NetworkDetector)
class NetworkDetector {
    func detectWiFiSSID() throws -> String {
        guard let store = SCDynamicStoreCreate(kCFAllocatorDefault, "com.ipupdater.panel" as CFString, nil, nil) else {
            throw NetworkError.noInterfaces
        }
        
        let patterns = [
            "State:/Network/Interface/[^/]+/IPv4" as CFString,
            "State:/Network/Interface/[^/]+/AirPort" as CFString
        ] as CFArray
        
        guard let dict = SCDynamicStoreCopyMultiple(store, nil, patterns) else {
            throw NetworkError.noWiFi
        }
        
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
            
            let name = String(cString: interface.ifa_name)
            // Accept any en* interface (en0, en1, en2, etc.) - covers Wi-Fi and Ethernet
            guard name.hasPrefix("en") else {
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
        if ip == "127.0.0.1" {
            return false
        }
        
        if ip.hasPrefix("169.254.") {
            return false
        }
        
        let parts = ip.split(separator: ".").compactMap { Int($0) }
        guard parts.count == 4 else {
            return false
        }
        
        let (a, b, _, _) = (parts[0], parts[1], parts[2], parts[3])
        
        if a == 10 {
            return true
        }
        
        if a == 172 && b >= 16 && b <= 31 {
            return true
        }
        
        if a == 192 && b == 168 {
            return true
        }
        
        return false
    }
}

enum NetworkError: Error {
    case noInterfaces
    case noWiFi
    case noPrivateIP
}
