import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class MetricFieldSpecs: QuickSpec {
    override func spec() {
        it("tagKey") {
            expect(MetricField.count.rawValue) == "count"
            expect(MetricField.total.rawValue) == "total"
            expect(MetricField.max.rawValue) == "max"
            expect(MetricField.mean.rawValue) == "mean"
        }
    }
}