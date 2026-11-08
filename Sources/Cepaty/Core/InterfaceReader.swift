import Darwin

/// Reads per-interface byte counters with getifaddrs (no entitlements needed).
/// NOTE: `if_data` counters are 32-bit and wrap at 4 GB; callers must subtract
/// with wrapping arithmetic (`&-`).
enum InterfaceReader {
    struct Counters {
        var rx: UInt32
        var tx: UInt32
    }

    static func read() -> [String: Counters] {
        var result: [String: Counters] = [:]
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return result }
        defer { freeifaddrs(head) }

        var cursor: UnsafeMutablePointer<ifaddrs>? = first
        while let node = cursor {
            let ifa = node.pointee
            if let addr = ifa.ifa_addr,
               addr.pointee.sa_family == UInt8(AF_LINK),
               let data = ifa.ifa_data {
                let name = String(cString: ifa.ifa_name)
                // Physical links only (Wi-Fi/Ethernet = en*, cellular = pdp_ip*);
                // skips lo0 and tunnels so VPN traffic is not counted twice.
                if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                    let d = data.assumingMemoryBound(to: if_data.self).pointee
                    result[name] = Counters(rx: d.ifi_ibytes, tx: d.ifi_obytes)
                }
            }
            cursor = ifa.ifa_next
        }
        return result
    }
}
