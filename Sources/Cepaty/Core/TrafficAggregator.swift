import Foundation

final class TrafficAggregator {
    private(set) var apps: [String: AppTraffic] = [:]
    private var previousBytes: [Int32: (bytesIn: UInt64, bytesOut: UInt64)] = [:]
    private var lastSampleDate: Date?
    private let resolver = AppResolver()

    func ingest(samples: [ProcessTraffic]) {
        let now = Date()
        let interval: TimeInterval
        if let last = lastSampleDate {
            interval = max(0.5, now.timeIntervalSince(last))
        } else {
            interval = 1.0
        }
        lastSampleDate = now

        let isFirstRun = previousBytes.isEmpty

        for key in apps.keys {
            apps[key]?.downSpeed = 0
            apps[key]?.upSpeed = 0
        }

        var currentPids = Set<Int32>()

        for sample in samples {
            currentPids.insert(sample.pid)
            let app = resolver.resolve(pid: sample.pid, fallbackName: sample.name)
            var traffic = apps[app.id] ?? AppTraffic(
                id: app.id,
                name: app.name,
                icon: app.icon,
                downSpeed: 0,
                upSpeed: 0,
                totalIn: 0,
                totalOut: 0
            )

            if !isFirstRun, let prev = previousBytes[sample.pid] {
                if sample.bytesIn >= prev.bytesIn && sample.bytesOut >= prev.bytesOut {
                    let deltaIn = sample.bytesIn - prev.bytesIn
                    let deltaOut = sample.bytesOut - prev.bytesOut

                    let down = Double(deltaIn) / interval
                    let up = Double(deltaOut) / interval

                    traffic.downSpeed += down
                    traffic.upSpeed += up
                    traffic.totalIn += deltaIn
                    traffic.totalOut += deltaOut
                }
            }

            previousBytes[sample.pid] = (sample.bytesIn, sample.bytesOut)
            apps[app.id] = traffic
        }

        previousBytes = previousBytes.filter { currentPids.contains($0.key) }
    }

    func resetSession() {
        apps.removeAll()
        previousBytes.removeAll()
        lastSampleDate = nil
    }

    func snapshot(sortedBy mode: SortMode) -> [AppTraffic] {
        return apps.values.sorted {
            if mode == .current {
                if $0.currentUsage != $1.currentUsage {
                    return $0.currentUsage > $1.currentUsage
                }
                return $0.sessionUsage > $1.sessionUsage
            } else {
                if $0.sessionUsage != $1.sessionUsage {
                    return $0.sessionUsage > $1.sessionUsage
                }
                return $0.currentUsage > $1.currentUsage
            }
        }
    }
}

enum SortMode: String, CaseIterable, Identifiable {
    case current = "Sekarang"
    case total = "Total"
    var id: String { rawValue }
}
