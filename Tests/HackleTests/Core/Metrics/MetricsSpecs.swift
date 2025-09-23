import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class MetricsSpecs: QuickSpec {
    override func spec() {

        beforeEach {
            Metrics.clear()
        }

        it("globalRegistry") {
            expect(Metrics.globalRegistry).to(beAnInstanceOf(DelegatingMetricRegistry.self))
        }

        it("metric") {
            let counter = Metrics.counter(name: "counter")
            let timer = Metrics.timer(name: "timer")

            counter.increment()
            timer.record(amount: 1, unit: .milliseconds)

            expect(Metrics.counter(name: "counter").count()) == 0
            expect(Metrics.timer(name: "timer").count()) == 0

            let cumulative = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: cumulative)

            counter.increment()
            timer.record(amount: 1, unit: .milliseconds)

            expect(Metrics.counter(name: "counter").count()) == 1
            expect(Metrics.timer(name: "timer").totalTime(unit: .milliseconds)) == 1.0

            Metrics.counter(name: "counter", tags: ["tag": "42"]).increment(42)
            Metrics.timer(name: "timer", tags: ["tag": "42"]).record(amount: 42, unit: .milliseconds)

            expect(Metrics.counter(name: "counter").count()) == 1
            expect(Metrics.timer(name: "timer").totalTime(unit: .milliseconds)) == 1.0

            expect(Metrics.counter(name: "counter", tags: ["tag": "42"]).count()) == 42
            expect(Metrics.timer(name: "timer", tags: ["tag": "42"]).totalTime(unit: .milliseconds)) == 42.0
        }
    }
}