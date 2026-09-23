import Combine
import Foundation

final class TrafficViewModel: ObservableObject {
    @Published private(set) var apps: [AppTraffic] = []
    @Published var sortMode: SortMode = .current { didSet { refresh() } }
    @Published var launchAtLogin: Bool = LaunchAtLogin.isEnabled {
        didSet {
            guard launchAtLogin != LaunchAtLogin.isEnabled else { return }
            LaunchAtLogin.setEnabled(launchAtLogin)
        }
    }

    private let sampler = NettopSampler()
    private let aggregator = TrafficAggregator()
    private var currentInterval = 5

    init() {
        sampler.onSnapshot = { [weak self] samples in
            guard let self else { return }
            self.aggregator.ingest(samples: samples)
            self.refresh()
        }
        sampler.start(interval: currentInterval)
    }

    func setPopoverVisible(_ visible: Bool) {
        let nextInterval = visible ? 1 : 5
        guard nextInterval != currentInterval else { return }
        currentInterval = nextInterval
        sampler.start(interval: currentInterval)
    }

    func stop() { sampler.stop() }
    private func refresh() { apps = aggregator.snapshot(sortedBy: sortMode) }
}
