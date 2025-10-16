import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class FlushMetricRegistrySpecs: QuickSpec {
    override func spec() {

        it("Counter") {
            let counter = FlushMetricRegistry(scheduler: Schedulers.dispatch(), pushInterval: 60).counter(name: "counter")
            expect(counter).to(beAnInstanceOf(FlushCounter.self))
        }

        it("Timer") {
            let timer = FlushMetricRegistry(scheduler: Schedulers.dispatch(), pushInterval: 60).timer(name: "timer")
            expect(timer).to(beAnInstanceOf(FlushTimer.self))
        }

        it("reset metric after publish") {
            class Registry: FlushMetricRegistry {
                var flushCount = 0

                override func flushMetrics(metrics: [Metric]) {
                    flushCount = flushCount + 1
                }
            }

            let registry = Registry(scheduler: Schedulers.dispatch(), pushInterval: 60)
            let counter = registry.counter(name: "counter")
            let timer = registry.timer(name: "timer")

            counter.increment(42)
            timer.record(amount: 42, unit: .nanoseconds)

            expect(counter.count()) == 42
            expect(timer.totalTime(unit: .nanoseconds)) == 42.0

            registry.publish()

            expect(counter.count()) == 0
            expect(timer.totalTime(unit: .nanoseconds)) == 0.0

            expect(registry.flushCount) == 1
        }
    }
}