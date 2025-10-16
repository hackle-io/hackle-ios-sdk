import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class DelegatingTimerSpecs: QuickSpec {
    override func spec() {
        it("등록된 Timer 가 없으면 0") {
            let timer = DelegatingMetricRegistry().timer(name: "timer")
            timer.record(amount: 42, unit: .milliseconds)
            expect(timer.count()) == 0
            expect(timer.totalTime(unit: .nanoseconds)) == 0.0
        }


        it("등록된 Timer 로 기록") {
            let delegating = DelegatingMetricRegistry()

            let cumulative1 = CumulativeMetricRegistry()
            let cumulative2 = CumulativeMetricRegistry()
            delegating.add(registry: cumulative1)
            delegating.add(registry: cumulative2)


            delegating.timer(name: "timer").record(amount: 42, unit: .nanoseconds)
            expect(delegating.timer(name: "timer").totalTime(unit: .nanoseconds)) == 42.0
            expect(cumulative1.timer(name: "timer").totalTime(unit: .nanoseconds)) == 42.0
            expect(cumulative2.timer(name: "timer").totalTime(unit: .nanoseconds)) == 42.0
        }

        it("measure") {
            let delegating = DelegatingMetricRegistry()
            let timer = delegating.timer(name: "timer")

            let measurements = timer.measure()
            expect(measurements.count) == 4
            expect(measurements[0].field) == .count
            expect(measurements[1].field) == .total
            expect(measurements[2].field) == .max
            expect(measurements[3].field) == .mean

            timer.record(amount: 42, unit: .milliseconds)
            expect(measurements[0].value) == 0.0
            expect(measurements[1].value) == 0.0
            expect(measurements[2].value) == 0.0
            expect(measurements[3].value) == 0.0

            delegating.add(registry: CumulativeMetricRegistry())
            timer.record(amount: 42, unit: .milliseconds)
            expect(measurements[0].value) == 1.0
            expect(measurements[1].value) == 42.0
            expect(measurements[2].value) == 42.0
            expect(measurements[3].value) == 42.0
        }
    }
}