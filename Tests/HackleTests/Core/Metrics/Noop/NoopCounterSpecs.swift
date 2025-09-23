import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class NoopCounterSpecs: QuickSpec {
    override func spec() {
        it("always zero") {
            let counter = NoopCounter(id: MetricId(name: "counter", tags: [:], type: .counter))
            expect(counter.count()) == 0

            let measurements = counter.measure()
            expect(measurements.count) == 1
            expect(measurements[0].value) == 0.0

            counter.increment()
            expect(counter.count()) == 0
            expect(measurements[0].value) == 0.0
        }
    }
}