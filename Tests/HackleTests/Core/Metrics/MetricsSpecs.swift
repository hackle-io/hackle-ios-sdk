import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class MetricsSpecs: QuickSpec {
    override func spec() {

        beforeEach {
            Metrics.clear()
            Metrics.queue.sync {}
        }

        it("globalRegistry") {
            expect(Metrics.globalRegistry).to(beAnInstanceOf(DelegatingMetricRegistry.self))
        }

        it("metric") {
            var counter: Counter!
            var timer: HackleTimer!

            Metrics.counter(name: "counter") { counter = $0 }
            Metrics.timer(name: "timer") { timer = $0 }
            Metrics.queue.sync {}

            counter.increment()
            timer.record(amount: 1, unit: .milliseconds)
            Metrics.queue.sync {}

            Metrics.counter(name: "counter") { expect($0.count()) == 0 }
            Metrics.timer(name: "timer") { expect($0.count()) == 0 }
            Metrics.queue.sync {}

            let cumulative = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: cumulative)
            Metrics.queue.sync {}

            counter.increment()
            timer.record(amount: 1, unit: .milliseconds)
            Metrics.queue.sync {}

            Metrics.counter(name: "counter") { expect($0.count()) == 1 }
            Metrics.timer(name: "timer") { expect($0.totalTime(unit: .milliseconds)) == 1.0 }
            Metrics.queue.sync {}

            Metrics.counter(name: "counter", tags: ["tag": "42"]) { $0.increment(42) }
            Metrics.timer(name: "timer", tags: ["tag": "42"]) { $0.record(amount: 42, unit: .milliseconds) }
            Metrics.queue.sync {}

            Metrics.counter(name: "counter") { expect($0.count()) == 1 }
            Metrics.timer(name: "timer") { expect($0.totalTime(unit: .milliseconds)) == 1.0 }
            Metrics.counter(name: "counter", tags: ["tag": "42"]) { expect($0.count()) == 42 }
            Metrics.timer(name: "timer", tags: ["tag": "42"]) { expect($0.totalTime(unit: .milliseconds)) == 42.0 }
            Metrics.queue.sync {}
        }
    }
}
