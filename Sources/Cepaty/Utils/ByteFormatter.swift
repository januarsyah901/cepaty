import Foundation

enum ByteFormatter {
    static func speed(_ bytesPerSec: Double) -> String {
        formatted(bytesPerSec) + "/s"
    }

    static func amount(_ bytes: UInt64) -> String {
        formatted(Double(bytes))
    }

    private static func formatted(_ value: Double) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var bytes = max(0, value)
        var index = 0
        while bytes >= 1024, index < units.count - 1 {
            bytes /= 1024
            index += 1
        }
        if index == 0 {
            return String(format: "%.0f B", bytes)
        } else if bytes < 10 {
            return String(format: "%.1f %@", bytes, units[index])
        } else {
            return String(format: "%.0f %@", bytes, units[index])
        }
    }
}
