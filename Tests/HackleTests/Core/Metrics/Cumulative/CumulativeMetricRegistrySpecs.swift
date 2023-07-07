import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class CumulativeMetricRegistrySpecs: QuickSpec {
    override func spec() {
        it("Counter") {
            let counter = CumulativeMetricRegistry().counter(name: "counter")
            expect(counter).to(beAnInstanceOf(CumulativeCounter.self))
        }

        it("Timer") {
            let timer = CumulativeMetricRegistry().timer(name: "counter")
            expect(timer).to(beAnInstanceOf(CumulativeTimer.self))
        }
    }
}