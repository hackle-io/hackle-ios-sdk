import Foundation
import Quick
import Nimble
@testable import Hackle


/// Regression specs for the metric registry concurrent-access bug fixed by the
/// "metric lock removal" design (2026-05-18).
///
/// Production crash context (pre-fix):
///  - `MonitoringMetricRegistry.doFlush()` calls `metrics` getter on `httpQueue` (read)
///  - URLSession delegate queue dispatches HTTP response → `ApiCallMetrics.record` →
///    `Metrics.timer(name:tags:)` → `_metrics[id] = newMetric` (write)
///
/// Post-fix design:
///  - All mutation goes through `Metrics.queue` (serial). Direct concurrent access
///    to internal sync APIs is "out of contract" but must still not crash thanks
///    to `AtomicReference` + value-typed `Dictionary`.
///
/// Run (optionally with TSan):
/// ```
/// xcodebuild test \
///     -scheme Hackle \
///     -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
///     -enableThreadSanitizer YES \
///     -only-testing:HackleTests/MetricRegistryRaceSpecs \
///     CODE_SIGNING_ALLOWED=NO
/// ```
class MetricRegistryRaceSpecs: QuickSpec {
    override func spec() {

        beforeEach {
            Metrics.clear()
            Metrics.sync()
        }

        afterEach {
            Metrics.clear()
            Metrics.sync()
        }

        it("Metrics.timer callback contract: concurrent writers + reader do not crash and do not lose registrations") {
            let cumulative = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: cumulative)
            Metrics.sync()

            // Unique name keeps the metric count assertion isolated from any
            // leftover metric IDs registered by other specs in the same run.
            let metricName = "stress.api.\(UUID().uuidString)"
            let writerCount = 8
            let writerIterations = 400
            let readerIterations = 20_000

            let group = DispatchGroup()

            for w in 0..<writerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<writerIterations {
                        let tags = ["w": "\(w)", "i": "\(i)"]
                        Metrics.timer(name: metricName, tags: tags) { timer in
                            timer.record(amount: Double(i), unit: .nanoseconds)
                        }
                    }
                }
            }

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<readerIterations {
                    _ = Metrics.globalRegistry.metrics.count
                }
            }

            group.wait()
            Metrics.sync()
            Metrics.sync()

            // Through the queued contract no registration is lost.
            let registered = Metrics.globalRegistry.metrics.filter { $0.id.name == metricName }
            expect(registered.count) == writerCount * writerIterations
        }

        it("DelegatingTimer.record concurrent dispatch: no crash, all amounts recorded") {
            let cumulative = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: cumulative)
            Metrics.sync()

            let timerName = "stress.timer.\(UUID().uuidString)"
            let recordIterations = 50_000

            let group = DispatchGroup()
            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<recordIterations {
                    Metrics.timer(name: timerName) { $0.record(amount: 1, unit: .nanoseconds) }
                }
            }
            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<recordIterations {
                    Metrics.timer(name: timerName) { $0.record(amount: 1, unit: .nanoseconds) }
                }
            }
            group.wait()
            Metrics.sync()
            Metrics.sync()

            expect(cumulative.timer(name: timerName).count()) == Int64(recordIterations * 2)
        }

        it("DelegatingCounter.increment concurrent dispatch: no crash, sum preserved") {
            let cumulative = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: cumulative)
            Metrics.sync()

            let counterName = "stress.counter.\(UUID().uuidString)"
            let incrementIterations = 50_000

            let group = DispatchGroup()
            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<incrementIterations {
                    Metrics.counter(name: counterName) { $0.increment(1) }
                }
            }
            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<incrementIterations {
                    Metrics.counter(name: counterName) { $0.increment(1) }
                }
            }
            group.wait()
            Metrics.sync()
            Metrics.sync()

            expect(cumulative.counter(name: counterName).count()) == Int64(incrementIterations * 2)
        }
    }
}
