import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class CounterSpecs: QuickSpec {
    override func spec() {
        it("CounterBuilder") {
            let counter = CounterBuilder(name: "counter")
                .tags(["a": "1", "b": "2"])
                .tag("c", "3")
                .register(registry: CumulativeMetricRegistry())

            expect(counter.id.name) == "counter"
            expect(counter.id.tags) == ["a": "1", "b": "2", "c": "3"]
            expect(counter.id.type) == .counter
        }
    }
}