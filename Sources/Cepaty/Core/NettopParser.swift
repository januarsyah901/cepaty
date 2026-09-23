import Foundation

enum NettopParser {
    static func parse(line: String) -> ProcessTraffic? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed.hasPrefix(",") {
            return nil
        }

        let fields = trimmed.split(separator: ",", omittingEmptySubsequences: false)
        guard fields.count >= 3 else { return nil }

        let process = String(fields[0]).trimmingCharacters(in: .whitespacesAndNewlines)
        guard let separator = process.lastIndex(of: "."),
              let pid = Int32(process[process.index(after: separator)...]),
              let bytesIn = UInt64(fields[1].trimmingCharacters(in: .whitespaces)),
              let bytesOut = UInt64(fields[2].trimmingCharacters(in: .whitespaces))
        else { return nil }

        let name = String(process[..<separator])
        guard !name.isEmpty else { return nil }
        return ProcessTraffic(pid: pid, name: name, bytesIn: bytesIn, bytesOut: bytesOut)
    }

    static func parseOutput(_ output: String) -> [ProcessTraffic] {
        var results: [ProcessTraffic] = []
        output.enumerateLines { line, _ in
            if let sample = parse(line: line) {
                results.append(sample)
            }
        }
        return results
    }
}
