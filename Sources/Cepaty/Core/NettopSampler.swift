import Foundation

final class NettopSampler {
    var onSnapshot: (([ProcessTraffic]) -> Void)?

    private var timer: DispatchSourceTimer?
    private let queue = DispatchQueue(label: "com.cepaty.nettop.sampler", qos: .utility)
    private var isRunning = false
    private var activeProcess: Process?

    func start(interval: Int) {
        stop()
        isRunning = true

        let timerSource = DispatchSource.makeTimerSource(queue: queue)
        timerSource.schedule(deadline: .now(), repeating: .seconds(interval), leeway: .milliseconds(100))
        timerSource.setEventHandler { [weak self] in
            self?.sample()
        }
        timer = timerSource
        timerSource.resume()
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
        if let proc = activeProcess, proc.isRunning {
            proc.terminate()
        }
        activeProcess = nil
    }

    private func sample() {
        guard isRunning else { return }
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/nettop")
        process.arguments = ["-P", "-n", "-x", "-L", "1", "-J", "bytes_in,bytes_out"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        activeProcess = process

        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            activeProcess = nil

            guard let text = String(data: data, encoding: .utf8) else { return }
            let samples = NettopParser.parseOutput(text)

            DispatchQueue.main.async { [weak self] in
                guard let self, self.isRunning else { return }
                self.onSnapshot?(samples)
            }
        } catch {
            activeProcess = nil
        }
    }
}
