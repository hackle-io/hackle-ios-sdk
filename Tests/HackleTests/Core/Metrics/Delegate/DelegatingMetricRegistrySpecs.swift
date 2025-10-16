import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class DelegatingMetricRegistrySpecs: QuickSpec {
    override func spec() {
        describe("create") {
            it("DelegationCounter") {
                let registry = DelegatingMetricRegistry()
                expect(registry.counter(name: "counter")).to(beAnInstanceOf(DelegatingCounter.self))
            }

            it("DelegatingTimer") {
                let registry = DelegatingMetricRegistry()
                expect(registry.timer(name: "timer")).to(beAnInstanceOf(DelegatingTimer.self))
            }
        }

        describe("add") {
            it("DelegatingMetricRegistry 는 추가하지 않는다") {
                let registry = DelegatingMetricRegistry()

                registry.add(registry: DelegatingMetricRegistry())
                registry.add(registry: DelegatingMetricRegistry())
                registry.add(registry: DelegatingMetricRegistry())
                registry.add(registry: DelegatingMetricRegistry())
                registry.add(registry: DelegatingMetricRegistry())

                let counter = registry.counter(name: "counter")
                counter.increment()

                expect(counter.count()) == 0
            }

            it("이미 추가된 Registry 는 추가하지 않는다") {
                let delegating = DelegatingMetricRegistry()
                let cumulative = CumulativeMetricRegistry()

                delegating.add(registry: cumulative)

                delegating.counter(name: "counter").increment(42)
                expect(cumulative.counter(name: "counter").count()) == 42

                delegating.add(registry: cumulative)
                expect(cumulative.counter(name: "counter").count()) == 42
            }

            it("metric before registry add") {
                let delegating = DelegatingMetricRegistry()
                let delegatingCounter = delegating.counter(name: "counter")
                delegatingCounter.increment()

                expect(delegatingCounter.count()) == 0

                let cumulative = CumulativeMetricRegistry()
                delegating.add(registry: cumulative)

                delegatingCounter.increment()

                expect(delegatingCounter.count()) == 1
                expect(cumulative.counter(name: "counter").count()) == 1
            }

            it("registry before metric add") {
                let delegating = DelegatingMetricRegistry()
                let cumulative = CumulativeMetricRegistry()
                delegating.add(registry: cumulative)

                delegating.counter(name: "counter").increment()

                expect(cumulative.counter(name: "counter").count()) == 1
            }
        }
        
        it("concurrency") {
            let registry = DelegatingMetricRegistry()
            let cumulativeRegistries = [CumulativeMetricRegistry](count: 500, create: CumulativeMetricRegistry())
            let q = DispatchQueue.concurrent()

            for it in 0..<1000 {
                q.async {
                    if it % 2 == 0 {
                        let _ = registry.counter(name: String(it))
                    } else {
                        registry.add(registry: cumulativeRegistries[it / 2])
                    }
                }

            }
            q.await()

            expect(registry.metrics.count) == 500
            for i in stride(from: 0, through: 1000, by: 2) {
                let name = String(i)
                registry.counter(name: name).increment()
                let count = cumulativeRegistries.sumOf { registry in
                    registry.counter(name: name).count()
                }
                expect(count) == 500
            }
        }
    }
}