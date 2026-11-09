import Combine
import Foundation

final class TrafficViewModel: ObservableObject {
    // Whole-machine rates (smoothed, bytes/s) and their history: from interface counters.
    @Published private(set) var down: Double = 0
    @Published private(set) var up: Double = 0
    @Published private(set) var history: [NetworkSample] = []
    // Per-app traffic: from the nettop stream.
    @Published private(set) var apps: [AppTraffic] = []
    /// True while the dropdown is visible. The sparkline only animates then.
    @Published private(set) var menuOpen = false

    @Published var sortMode: SortMode = .current { didSet { refresh() } }
    @Published var launchAtLogin: Bool = LaunchAtLogin.isEnabled {
        didSet {
            guard launchAtLogin != LaunchAtLogin.isEnabled else { return }
            LaunchAtLogin.setEnabled(launchAtLogin)
        }
    }

    /// How much history the sparkline shows.
    static let window: TimeInterval = 300

    private let sampler = NettopSampler()
    private let aggregator = TrafficAggregator()
    /// Closed-menu interval. Per-app totals come from cumulative counters, so a longer
    /// interval loses no bytes (only processes that start and exit between samples).
    private static let idleInterval = 10
    private var currentInterval = idleInterval
    private var interfaceTimer: Timer?
    private var lastCounters: [String: InterfaceReader.Counters] = [:]
    private var lastTick: Date?
    private let alpha = 0.4   // EMA smoothing factor

    init() {
        sampler.onSnapshot = { [weak self] samples in
            guard let self else { return }
            self.aggregator.ingest(samples: samples)
            self.refresh()
        }
    }

    func start() {
        startInterfaceTimer()
        sampler.start(interval: currentInterval)
    }

    /// While the menu is open: per-app data every second. Closed: every 5 s (cheap).
    func setMenuOpen(_ open: Bool) {
        menuOpen = open
        let next = open ? 1 : Self.idleInterval
        guard next != currentInterval else { return }
        currentInterval = next
        sampler.start(interval: next)
    }

    func stop() {
        sampler.stop()
        interfaceTimer?.invalidate()
        interfaceTimer = nil
    }

    private func refresh() { apps = aggregator.snapshot(sortedBy: sortMode) }

    // MARK: Interface sampling

    private func startInterfaceTimer() {
        interfaceTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in self?.tick() }
        timer.tolerance = 0.2   // lets the system coalesce wakeups
        RunLoop.main.add(timer, forMode: .common)   // .common keeps firing while a menu is open
        interfaceTimer = timer
        tick()
    }

    private func tick() {
        let now = Date()
        let current = InterfaceReader.read()
        defer { lastCounters = current; lastTick = now }
        guard let previousTime = lastTick else { return }
        let dt = now.timeIntervalSince(previousTime)
        guard dt > 0.05 else { return }

        var d: UInt64 = 0
        var u: UInt64 = 0
        for (name, c) in current {
            guard let p = lastCounters[name] else { continue }
            d += UInt64(c.rx &- p.rx)   // 32-bit counters wrap: subtract with wrapping
            u += UInt64(c.tx &- p.tx)
        }
        let rawDown = Double(d) / dt
        let rawUp = Double(u) / dt
        guard rawDown < 5e9, rawUp < 5e9 else { return }   // ignore counter resets

        down = alpha * rawDown + (1 - alpha) * down
        up = alpha * rawUp + (1 - alpha) * up
        if down < 1 { down = 0 }
        if up < 1 { up = 0 }

        history.append(NetworkSample(time: now, down: down, up: up))
        let cutoff = now.addingTimeInterval(-Self.window - 5)
        if let firstKeep = history.firstIndex(where: { $0.time >= cutoff }), firstKeep > 0 {
            history.removeFirst(firstKeep)
        }
    }
}
