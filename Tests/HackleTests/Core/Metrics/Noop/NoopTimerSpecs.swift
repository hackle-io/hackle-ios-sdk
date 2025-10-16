import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class NoopTimerSpecs: QuickSpec {
    override func spec() {
        it("always zero") {
            let timer = NoopTimer(id: MetricId(name: "timer", tags: [:], type: .timer))
            expect(timer.count()) == 0
            expect(timer.totalTime(unit: .nanoseconds)) == 0.0
            expect(timer.max(unit: .nanoseconds)) == 0.0
            expect(timer.mean(unit: .nanoseconds)) == 0.0

            let measurements = timer.measure()
            expect(measurements.count) == 4
            expect(measurements.allSatisfy {
                $0.value == 0.0
            }) == true

            timer.record(amount: 42, unit: .nanoseconds)

            expect(timer.count()) == 0
            expect(timer.totalTime(unit: .nanoseconds)) == 0.0
            expect(timer.max(unit: .nanoseconds)) == 0.0
            expect(timer.mean(unit: .nanoseconds)) == 0.0
            expect(measurements.count) == 4
            expect(measurements.allSatisfy {
                $0.value == 0.0
            }) == true
        }
    }
}