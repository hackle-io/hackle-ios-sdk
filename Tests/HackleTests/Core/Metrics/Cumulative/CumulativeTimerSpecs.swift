import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class CumulativeTimerSpecs: QuickSpec {
    override func spec() {

        it("negative records should ignored") {
            let timer = CumulativeMetricRegistry().timer(name: "timer")
            timer.record(amount: -1, unit: .nanoseconds)
            expect(timer.count()) == 0
        }

        it("concurrency") {
            let timer = CumulativeMetricRegistry().timer(name: "timer")

            let q = DispatchQueue.concurrent()
            for duration in (1...10_000) {
                q.async {
                    timer.record(amount: Double(duration), unit: .nanoseconds)
                }
            }
            q.await()

            expect(timer.count()) == 10_000
            expect(timer.totalTime(unit: .nanoseconds)) == 50005000.0
            expect(timer.max(unit: .nanoseconds)) == 10000.0
            expect(timer.mean(unit: .nanoseconds)) == 5000.5
        }

        it("measure") {
            let timer = CumulativeMetricRegistry().timer(name: "timer")
            let measurements = timer.measure()

            expect(measurements.count) == 4
            expect(measurements[0].field) == .count
            expect(measurements[1].field) == .total
            expect(measurements[2].field) == .max
            expect(measurements[3].field) == .mean

            expect(measurements[0].value) == 0.0
            expect(measurements[1].value) == 0.0
            expect(measurements[2].value) == 0.0
            expect(measurements[3].value) == 0.0

            timer.record(amount: 42, unit: .milliseconds)
            expect(measurements[0].field) == .count
            expect(measurements[0].value) == 1.0
            expect(measurements[1].value) == 42.0
            expect(measurements[2].value) == 42.0
            expect(measurements[3].value) == 42.0
        }
    }
}