import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class DelegatingCounterSpecs: QuickSpec {
    override func spec() {

        it("등록된 Counter 가 없으면 0") {
            let counter = DelegatingMetricRegistry().counter(name: "counter")
            counter.increment(42)
            expect(counter.count()) == 0
        }

        it("등록된 Counter 증가") {
            let delegating = DelegatingMetricRegistry()

            let cumulative1 = CumulativeMetricRegistry()
            let cumulative2 = CumulativeMetricRegistry()
            delegating.add(registry: cumulative1)
            delegating.add(registry: cumulative2)


            delegating.counter(name: "counter").increment(42)
            expect(delegating.counter(name: "counter").count()) == 42
            expect(cumulative1.counter(name: "counter").count()) == 42
            expect(cumulative2.counter(name: "counter").count()) == 42
        }

        it("measure") {
            let delegating = DelegatingMetricRegistry()
            let counter = delegating.counter(name: "counter")

            let measurements = counter.measure()
            expect(measurements.count) == 1
            expect(measurements[0].field) == .count
            expect(measurements[0].value) == 0.0

            counter.increment(42)
            expect(measurements[0].value) == 0.0

            delegating.add(registry: CumulativeMetricRegistry())
            counter.increment(42)
            expect(measurements[0].value) == 42.0
        }
    }
}