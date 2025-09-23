import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class CumulativeCounterSpecs: QuickSpec {
    override func spec() {
        it("concurrency") {
            let counter = CumulativeMetricRegistry().counter(name: "counter")

            let q = DispatchQueue.concurrent()
            for _ in (0..<10_000) {
                q.async {
                    counter.increment()
                }
            }

            q.await()
            expect(counter.count()) == 10_000
        }

        it("measure") {
            let counter = CumulativeMetricRegistry().counter(name: "counter")
            let measurements = counter.measure()

            expect(measurements.count) == 1
            expect(measurements[0].value) == 0.0

            counter.increment(42)
            expect(measurements[0].value) == 42.0
        }
    }
}
