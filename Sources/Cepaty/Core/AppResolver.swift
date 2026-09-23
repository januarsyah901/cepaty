import AppKit

final class AppResolver {
    private var cache: [Int32: ResolvedApp] = [:]

    func resolve(pid: Int32, fallbackName: String) -> ResolvedApp {
        if let cached = cache[pid] { return cached }
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            let identifier = normalizedIdentifier(fallbackName)
            let resolved = ResolvedApp(id: identifier, name: cleanedName(fallbackName), icon: nil)
            cache[pid] = resolved
            return resolved
        }

        let rawIdentifier = app.bundleIdentifier ?? fallbackName
        let identifier = normalizedIdentifier(rawIdentifier)
        let resolved = ResolvedApp(id: identifier, name: app.localizedName ?? cleanedName(fallbackName), icon: app.icon)
        cache[pid] = resolved
        return resolved
    }

    private func normalizedIdentifier(_ identifier: String) -> String {
        var result = identifier
        let suffixes = [".helper", ".renderer", ".pluginhost", ".gpu", ".service", " helper", " renderer"]
        for suffix in suffixes {
            if result.lowercased().hasSuffix(suffix) {
                result = String(result.dropLast(suffix.count))
            }
        }
        return result
    }

    private func cleanedName(_ rawName: String) -> String {
        return rawName.replacingOccurrences(of: ".", with: " ")
    }
}
