import AppKit
import Foundation

struct ProcessTraffic: Sendable, Equatable {
    let pid: Int32
    let name: String
    let bytesIn: UInt64
    let bytesOut: UInt64
}

struct ResolvedApp {
    let id: String
    let name: String
    let icon: NSImage?
}

struct AppTraffic: Identifiable {
    let id: String
    var name: String
    var icon: NSImage?
    var downSpeed: Double
    var upSpeed: Double
    var totalIn: UInt64
    var totalOut: UInt64

    var currentUsage: Double { downSpeed + upSpeed }
    var sessionUsage: UInt64 { totalIn + totalOut }
}
