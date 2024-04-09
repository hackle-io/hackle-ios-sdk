import Foundation
import Quick
import Nimble
@testable import Hackle


class ScopingThrottleLimiterSpecs: QuickSpec {
    override func spec() {
        it("throttle 1") {
            let sut = ScopingThrottleLimiter(interval: 1, limit: 1, clock: SystemClock.shared)
            expect(sut.tryAcquire()).to(equal(true))
            for _ in 0..<10 {
                expect(sut.tryAcquire()).to(equal(false))
            }
        }

        it("throttle N") {
            let sut = ScopingThrottleLimiter(interval: 10, limit: 10, clock: SystemClock.shared)
            let results = (0..<100).map { i in
                sut.tryAcquire()
            }

            expect(results.filter {
                    $0
                }
                .count)
                .to(equal(10))
            expect(results.filter {
                    !$0
                }
                .count)
                .to(equal(90))
        }

        it("refresh after interval") {
            let clock = ClockStub(results: [Date(timeIntervalSince1970: 0), Date(timeIntervalSince1970: 100), Date(timeIntervalSince1970: 101)])
            let sut = ScopingThrottleLimiter(interval: 100, limit: 1, clock: clock)

            expect(sut.tryAcquire()).to(equal(true))
            expect(sut.tryAcquire()).to(equal(false))
            expect(sut.tryAcquire()).to(equal(true))
        }

        it("concurrency") {
            let sut = ScopingThrottleLimiter(interval: 1, limit: 100, clock: SystemClock.shared)

            let counter = CumulativeMetricRegistry().counter(name: "counter")

            let queues = (0..<8).map { _ in
                let q = DispatchQueue.concurrent()
                q.async {
                    for _ in (0..<100) {
                        if sut.tryAcquire() {
                            counter.increment()
                        }
                    }
                }
                return q
            }
            queues.forEach { q in
                q.await()
            }
            expect(counter.count()).to(equal(100))
        }
    }
}

private class ClockStub: Clock {


    private let results: [Date]
    private var i = 0

    init(results: [Date]) {
        self.results = results
    }


    func now() -> Date {
        let result = results[i]
        i += 1
        return result
    }

    func currentMillis() -> Int64 {
        0
    }

    func tick() -> UInt64 {
        0
    }

}