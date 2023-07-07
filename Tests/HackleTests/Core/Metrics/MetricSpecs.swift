import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class MetricSpecs: QuickSpec {
    override func spec() {

        it("Equatable") {
            let counter1 = MetricId(name: "counter_1", tags: [:], type: .counter)
            let counter1_ = MetricId(name: "counter_1", tags: [:], type: .counter)
            let counter1__ = MetricId(name: "counter_1", tags: ["a": "b"], type: .counter)
            let counter2 = MetricId(name: "counter_2", tags: [:], type: .counter)
            let timer = MetricId(name: "counter_1", tags: [:], type: .timer)

            expect(counter1) == counter1
            expect(counter1) == counter1_
            expect(counter1) != counter1__
            expect(counter1) == timer
            expect(counter1) != counter2
        }

        it("Hashable") {
            let counter1 = MetricId(name: "counter_1", tags: [:], type: .counter)
            let counter1_ = MetricId(name: "counter_1", tags: [:], type: .counter)
            let counter1__ = MetricId(name: "counter_1", tags: ["a": "b"], type: .counter)
            let counter2 = MetricId(name: "counter_2", tags: [:], type: .counter)
            let timer = MetricId(name: "counter_1", tags: [:], type: .timer)

            expect(counter1.hashValue) == counter1.hashValue
            expect(counter1.hashValue) == counter1_.hashValue
            expect(counter1.hashValue) != counter1__.hashValue
            expect(counter1.hashValue == timer.hashValue)
            expect(counter1.hashValue) != counter2.hashValue
        }

        it("MetricType") {
            expect(MetricType.counter.rawValue) == "COUNTER"
            expect(MetricType.timer.rawValue) == "TIMER"
        }
    }
}