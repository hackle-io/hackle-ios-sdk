import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class FlushCounterSpecs: QuickSpec {
    override func spec() {

        it("increment") {
            let counter = FlushCounter(id: MetricId(name: "counter", tags: [:], type: .counter))
            for i in 1...100 {
                counter.increment()
                expect(counter.count()) == Int64(i)
            }
        }

        it("increment & flush") {
            let flushCounter = FlushCounter(id: MetricId(name: "counter", tags: [:], type: .counter))
            for i in 1...100 {
                flushCounter.increment()
                expect(flushCounter.count()) == Int64(i)
            }
            let counter = flushCounter.flush() as! Counter
            expect(counter.count()) == 100
            for i in 1...100 {
                flushCounter.increment()
                expect(flushCounter.count()) == Int64(i)
            }
        }

        it("concurrency") {
            for _ in 1...10 {
                let counter = FlushCounter(id: MetricId(name: "counter", tags: [:], type: .counter))

                var flushed = [Counter?](repeating: nil, count: 5001)
                let q = DispatchQueue.concurrent()
                for i in 1...10000 {
                    q.async {
                        if i % 2 == 0 {
                            counter.increment()
                        } else {
                            flushed[i / 2] = (counter.flush() as! Counter)
                        }
                    }
                }

                q.await()
                flushed.append((counter.flush() as! Counter))

                let count = flushed.sumOf { counter in
                    counter?.count() ?? 0
                }
                expect(count) == 5000
            }
        }

        it("measure") {
            let counter = FlushCounter(id: MetricId(name: "counter", tags: [:], type: .counter))
            counter.increment(42)

            let measurements = counter.measure()
            expect(measurements.count) == 1
            expect(measurements[0].field) == .count
            expect(measurements[0].value) == 42.0

            counter.flush()

            expect(measurements[0].value) == 0.0
        }
    }
}