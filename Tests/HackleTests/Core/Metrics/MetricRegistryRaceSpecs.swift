import Foundation
import Quick
import Nimble
@testable import Hackle


/// Stress spec reproducing the production race in metric registry concurrent access.
///
/// Production crash context:
///  - `MonitoringMetricRegistry.doFlush()` calls `metrics` getter on `httpQueue` (read)
///  - URLSession delegate queue dispatches HTTP response → `ApiCallMetrics.record` →
///    `Metrics.timer(name:tags:)` → `_metrics[id] = newMetric` (write)
///
/// Concurrent access to the Swift `Dictionary` triggers a buffer-rehash / ARC race
/// that crashes in production. This spec forces the same pattern so Thread Sanitizer
/// reports the race.
///
/// Run:
/// ```
/// xcodebuild test \
///     -scheme Hackle \
///     -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=26.2' \
///     -enableThreadSanitizer YES \
///     -only-testing:HackleTests/MetricRegistryRaceSpecs \
///     CODE_SIGNING_ALLOWED=NO
/// ```
class MetricRegistryRaceSpecs: QuickSpec {
    override class func spec() {

        it("MetricRegistry: concurrent timer creation vs metrics iteration") {
            // Mirrors production doFlush vs record pattern on a local registry —
            // production race (`_metrics` reader vs writer) is reproduced without
            // touching `Metrics.globalRegistry`.
            let delegating = DelegatingMetricRegistry()
            let cumulative = CumulativeMetricRegistry()
            delegating.add(registry: cumulative)

            let writerCount = 8
            let writerIterations = 400
            let readerIterations = 20_000

            let group = DispatchGroup()

            for w in 0..<writerCount {
                DispatchQueue.global(qos: .utility).async(group: group) {
                    for i in 0..<writerIterations {
                        let tags = ["w": "\(w)", "i": "\(i)"]
                        let timer = delegating.timer(name: "stress.api", tags: tags)
                        timer.record(amount: Double(i), unit: .nanoseconds)
                    }
                }
            }

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<readerIterations {
                    let snapshot = delegating.metrics
                    _ = snapshot.count
                }
            }

            group.wait()

            expect(delegating.metrics.count) == writerCount * writerIterations
        }

        it("DelegatingTimer: concurrent record vs add(registry:)") {
            // Reproduces DelegatingTimer._timers race.
            // - writer: add(registry:) writes to _timers
            // - reader: record(amount:unit:) reads _timers via the timers getter
            let delegating = DelegatingMetricRegistry()
            let timer = delegating.timer(name: "stress.timer")

            let recordIterations = 50_000
            let addIterations = 500

            let group = DispatchGroup()

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<recordIterations {
                    timer.record(amount: 1, unit: .nanoseconds)
                }
            }

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<addIterations {
                    delegating.add(registry: CumulativeMetricRegistry())
                }
            }

            group.wait()

            let baseline = timer.count()
            timer.record(amount: 1, unit: .nanoseconds)
            expect(timer.count()) == baseline + 1
        }

        it("DelegatingCounter: concurrent increment vs add(registry:)") {
            // Same pattern as DelegatingTimer — reproduces DelegatingCounter._counters race.
            let delegating = DelegatingMetricRegistry()
            let counter = delegating.counter(name: "stress.counter")

            let incrementIterations = 50_000
            let addIterations = 500

            let group = DispatchGroup()

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<incrementIterations {
                    counter.increment(1)
                }
            }

            DispatchQueue.global(qos: .utility).async(group: group) {
                for _ in 0..<addIterations {
                    delegating.add(registry: CumulativeMetricRegistry())
                }
            }

            group.wait()

            let baseline = counter.count()
            counter.increment(1)
            expect(counter.count()) == baseline + 1
        }
    }
}
