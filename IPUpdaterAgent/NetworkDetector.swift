import Foundation
import SystemConfiguration
import SystemConfiguration.CaptiveNetwork
import Darwin

class NetworkDetector {
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
        
        guard let interfaces = CNCopySupportedInterfaces() as? [String] else {
            throw NetworkError.noInterfaces
        }
        
        for interface in interfaces {
            guard let info = CNCopyCurrentNetworkInfo(interface as CFString) as? [String: Any],
                  let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                continue
            }
            return ssid
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

enum NetworkError: Error {
    case noInterfaces
    case noWiFi
    case noPrivateIP
}

