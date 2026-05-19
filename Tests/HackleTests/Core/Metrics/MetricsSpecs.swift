import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


extension Metrics {
    static func sync() {
        queue.sync {}
    }
}


class MetricsSpecs: QuickSpec {
    override func spec() {

        beforeEach {
            Metrics.clear()
            Metrics.sync()
        }

        it("globalRegistry") {
            expect(Metrics.globalRegistry).to(beAnInstanceOf(DelegatingMetricRegistry.self))
        }

        it("metric") {
            Metrics.counter(name: "counter") { $0.increment() }
            Metrics.timer(name: "timer") { $0.record(amount: 1, unit: .milliseconds) }
            Metrics.sync()
            Metrics.sync()

            Metrics.counter(name: "counter") { expect($0.count()) == 0 }
            Metrics.timer(name: "timer") { expect($0.count()) == 0 }
            Metrics.sync()

            let cumulative = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: cumulative)
            Metrics.sync()

            Metrics.counter(name: "counter") { $0.increment() }
            Metrics.timer(name: "timer") { $0.record(amount: 1, unit: .milliseconds) }
            Metrics.sync()
            Metrics.sync()

            Metrics.counter(name: "counter") { expect($0.count()) == 1 }
            Metrics.timer(name: "timer") { expect($0.totalTime(unit: .milliseconds)) == 1.0 }
            Metrics.sync()

            Metrics.counter(name: "counter", tags: ["tag": "42"]) { $0.increment(42) }
            Metrics.timer(name: "timer", tags: ["tag": "42"]) { $0.record(amount: 42, unit: .milliseconds) }
            Metrics.sync()
            Metrics.sync()

            Metrics.counter(name: "counter") { expect($0.count()) == 1 }
            Metrics.timer(name: "timer") { expect($0.totalTime(unit: .milliseconds)) == 1.0 }
            Metrics.counter(name: "counter", tags: ["tag": "42"]) { expect($0.count()) == 42 }
            Metrics.timer(name: "timer", tags: ["tag": "42"]) { expect($0.totalTime(unit: .milliseconds)) == 42.0 }
            Metrics.sync()
        }
    }
}
