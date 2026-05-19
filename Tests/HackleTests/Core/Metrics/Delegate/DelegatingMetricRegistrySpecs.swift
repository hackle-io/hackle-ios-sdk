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
                Metrics.sync()

                expect(counter.count()) == 0
            }

            it("이미 추가된 Registry 는 추가하지 않는다") {
                let delegating = DelegatingMetricRegistry()
                let cumulative = CumulativeMetricRegistry()

                delegating.add(registry: cumulative)

                delegating.counter(name: "counter").increment(42)
                Metrics.sync()
                expect(cumulative.counter(name: "counter").count()) == 42

                delegating.add(registry: cumulative)
                expect(cumulative.counter(name: "counter").count()) == 42
            }

            it("metric before registry add") {
                let delegating = DelegatingMetricRegistry()
                let delegatingCounter = delegating.counter(name: "counter")
                delegatingCounter.increment()
                Metrics.sync()

                expect(delegatingCounter.count()) == 0

                let cumulative = CumulativeMetricRegistry()
                delegating.add(registry: cumulative)

                delegatingCounter.increment()
                Metrics.sync()

                expect(delegatingCounter.count()) == 1
                expect(cumulative.counter(name: "counter").count()) == 1
            }

            it("registry before metric add") {
                let delegating = DelegatingMetricRegistry()
                let cumulative = CumulativeMetricRegistry()
                delegating.add(registry: cumulative)

                delegating.counter(name: "counter").increment()
                Metrics.sync()

                expect(cumulative.counter(name: "counter").count()) == 1
            }
        }

        it("concurrency via Metrics.queue contract") {
            // 새 contract: 동시 호출자는 `Metrics.counter` callback API를 쓰며,
            // 모든 mutation은 `Metrics.queue`에서 직렬화된다. 이전 테스트가
            // 로컬 registry를 raw concurrent로 두드리던 패턴은 contract 밖이라 제거함.
            Metrics.clear()
            Metrics.sync()

            let cumulative = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: cumulative)
            Metrics.sync()

            let q = DispatchQueue.concurrent()
            for it in 0..<1000 {
                q.async {
                    if it % 2 == 0 {
                        Metrics.counter(name: "concurrency.\(it)") { _ in }
                    } else {
                        Metrics.counter(name: "concurrency.\(it - 1)") { $0.increment() }
                    }
                }
            }
            q.await()
            Metrics.sync()
            Metrics.sync()

            // 500개의 짝수 i에 대해 counter("concurrency.{i}")가 등록됐고,
            // 동일 i에 대해 홀수 it = i+1에서 한 번씩 increment된다.
            for i in stride(from: 0, to: 1000, by: 2) {
                expect(cumulative.counter(name: "concurrency.\(i)").count()) == 1
            }

            // cleanup global state
            Metrics.clear()
            Metrics.sync()
        }
    }
}
