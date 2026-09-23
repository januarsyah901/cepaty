import Foundation

struct TestRunner {
    private static var passed = 0
    private static var failed = 0

    static func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String, file: String = #file, line: Int = #line) {
        if actual == expected {
            passed += 1
            print("  ✓ \(message)")
        } else {
            failed += 1
            print("  ✗ \(message) [FAILED]")
            print("    Expected: \(expected)")
            print("    Got:      \(actual)")
            print("    At: \(file):\(line)")
        }
    }

    static func assertNil<T>(_ value: T?, _ message: String, file: String = #file, line: Int = #line) {
        if value == nil {
            passed += 1
            print("  ✓ \(message)")
        } else {
            failed += 1
            print("  ✗ \(message) [FAILED]")
            print("    Expected nil, got: \(String(describing: value))")
            print("    At: \(file):\(line)")
        }
    }

    static func runAllTests() -> Bool {
        passed = 0
        failed = 0

        print("========================================")
        print("Running Cepaty MenuBarTraffic Test Suite")
        print("========================================\n")

        print("[NettopParser Tests]")
        testParsesNameWithSpacesAndDots()
        testSkipsInvalidRows()
        testParsesFullOutput()

        print("\n[ByteFormatter Tests]")
        testByteFormatterSpeed()
        testByteFormatterAmount()

        print("\n[TrafficAggregator Tests]")
        testAggregatorBaselineAndSecondTick()
        testAggregatorResetSpeedWhenProcessStops()
        testSortingModes()

        print("\n========================================")
        print("Summary: \(passed) passed, \(failed) failed")
        print("========================================")

        return failed == 0
    }

    // MARK: - NettopParser Tests
    private static func testParsesNameWithSpacesAndDots() {
        let sample = NettopParser.parse(line: "Google.Chrome Helper.1234,2048,1024")
        assertEqual(sample?.name, "Google.Chrome Helper", "Parse name with dots & spaces")
        assertEqual(sample?.pid, 1234, "Parse PID")
        assertEqual(sample?.bytesIn, 2048, "Parse bytesIn")
        assertEqual(sample?.bytesOut, 1024, "Parse bytesOut")
    }

    private static func testSkipsInvalidRows() {
        assertNil(NettopParser.parse(line: ""), "Skip empty line")
        assertNil(NettopParser.parse(line: ",bytes_in,bytes_out,"), "Skip header line")
        assertNil(NettopParser.parse(line: "process.abc,5,7"), "Skip non-numeric PID")
        assertNil(NettopParser.parse(line: "process.1,not-a-number,7"), "Skip non-numeric bytes")
    }

    private static func testParsesFullOutput() {
        let raw = """
        ,bytes_in,bytes_out,
        launchd.1,0,0,
        Safari.123,4096,2048,
        
        """
        let samples = NettopParser.parseOutput(raw)
        assertEqual(samples.count, 2, "Parse full output line count")
        assertEqual(samples.first?.name, "launchd", "First process name")
        assertEqual(samples.last?.name, "Safari", "Second process name")
    }

    // MARK: - ByteFormatter Tests
    private static func testByteFormatterSpeed() {
        assertEqual(ByteFormatter.speed(0), "0 B/s", "Format 0 B/s")
        assertEqual(ByteFormatter.speed(500), "500 B/s", "Format 500 B/s")
        assertEqual(ByteFormatter.speed(1536), "1.5 KB/s", "Format 1.5 KB/s")
        assertEqual(ByteFormatter.speed(10485760), "10 MB/s", "Format 10 MB/s")
    }

    private static func testByteFormatterAmount() {
        assertEqual(ByteFormatter.amount(0), "0 B", "Format 0 B")
        assertEqual(ByteFormatter.amount(2048), "2.0 KB", "Format 2.0 KB")
        assertEqual(ByteFormatter.amount(1048576), "1.0 MB", "Format 1.0 MB")
    }

    // MARK: - TrafficAggregator Tests
    private static func testAggregatorBaselineAndSecondTick() {
        let aggregator = TrafficAggregator()

        // First snapshot baseline: Safari has 50000 cumulative in, 10000 out
        let baseline = [ProcessTraffic(pid: 100, name: "Safari", bytesIn: 50000, bytesOut: 10000)]
        aggregator.ingest(samples: baseline)

        // Baseline snapshot should not compute live B/s speed
        var snapshot = aggregator.snapshot(sortedBy: .current)
        assertEqual(snapshot.first?.downSpeed, 0.0, "Baseline downSpeed should be 0")
        assertEqual(snapshot.first?.upSpeed, 0.0, "Baseline upSpeed should be 0")

        // Second snapshot: Safari transmitted 2000 in, 1000 out more
        let second = [ProcessTraffic(pid: 100, name: "Safari", bytesIn: 52000, bytesOut: 11000)]
        aggregator.ingest(samples: second)

        snapshot = aggregator.snapshot(sortedBy: .current)
        assertEqual(snapshot.first?.totalIn, UInt64(2000), "Tick 2 totalIn session delta")
        assertEqual(snapshot.first?.totalOut, UInt64(1000), "Tick 2 totalOut session delta")
    }

    private static func testAggregatorResetSpeedWhenProcessStops() {
        let aggregator = TrafficAggregator()

        // Snapshot 1 baseline
        aggregator.ingest(samples: [ProcessTraffic(pid: 200, name: "Slack", bytesIn: 1000, bytesOut: 1000)])
        // Snapshot 2 active
        aggregator.ingest(samples: [ProcessTraffic(pid: 200, name: "Slack", bytesIn: 6000, bytesOut: 6000)])

        // Snapshot 3: Slack process closes or is silent
        aggregator.ingest(samples: [])
        assertEqual(aggregator.snapshot(sortedBy: .current).first?.downSpeed, 0.0, "Slack speed reset to 0 when idle")
    }

    private static func testSortingModes() {
        let aggregator = TrafficAggregator()

        // Baseline
        aggregator.ingest(samples: [
            ProcessTraffic(pid: 1, name: "AppA", bytesIn: 0, bytesOut: 0),
            ProcessTraffic(pid: 2, name: "AppB", bytesIn: 0, bytesOut: 0)
        ])

        // App A: high current speed (10000 bytes)
        // App B: lower current speed (1000 bytes)
        aggregator.ingest(samples: [
            ProcessTraffic(pid: 1, name: "AppA", bytesIn: 10000, bytesOut: 0),
            ProcessTraffic(pid: 2, name: "AppB", bytesIn: 1000, bytesOut: 0)
        ])

        let sortedCurrent = aggregator.snapshot(sortedBy: .current)
        assertEqual(sortedCurrent.first?.name, "AppA", "Sort by current speed gives AppA first")

        let sortedTotal = aggregator.snapshot(sortedBy: .total)
        assertEqual(sortedTotal.first?.name, "AppA", "Sort by total usage gives AppA first")
    }
}
