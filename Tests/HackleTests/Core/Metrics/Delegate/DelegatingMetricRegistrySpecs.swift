import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class DelegatingMetricRegistrySpecs: QuickSpec {
    override class func spec() {
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

            it("재진입 — sub-registry add 후 timer 생성이 hang 없이 완료") {
                // addRegistries는 getOrCreateMetric의 lock 보유 상태에서 호출된다.
                // RecursiveLock이 아닌 mutex/RW lock으로 회귀하면 이 호출은 deadlock된다.
                // DispatchSemaphore로 hang을 명시적으로 감지한다.
                let delegating = DelegatingMetricRegistry()
                delegating.add(registry: CumulativeMetricRegistry())
                delegating.add(registry: CumulativeMetricRegistry())

                let done = DispatchSemaphore(value: 0)
                DispatchQueue.global(qos: .utility).async {
                    _ = delegating.timer(name: "reentrant.timer")
                    _ = delegating.counter(name: "reentrant.counter")
                    done.signal()
                }

                let result = done.wait(timeout: .now() + 2.0)
                expect(result) == .success
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
