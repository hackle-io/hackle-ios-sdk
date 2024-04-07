import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultThrottlerSpecs: QuickSpec {

    override func spec() {
        it("when cannot acquire then execute reject") {
            // given
            let limiter = ThrottleLimiterStub(acquired: false)
            let sut = DefaultThrottler(limiter: limiter)

            var accept = 0
            var reject = 0

            // when
            sut.execute(accept: { accept += 1 }, reject: { reject += 1 })

            // then
            expect(accept).to(equal(0))
            expect(reject).to(equal(1))
        }

        it("when acquire then execute accept") {
            // given
            let limiter = ThrottleLimiterStub(acquired: true)
            let sut = DefaultThrottler(limiter: limiter)

            var accept = 0
            var reject = 0

            // when
            sut.execute(accept: { accept += 1 }, reject: { reject += 1 })

            // then
            expect(accept).to(equal(1))
            expect(reject).to(equal(0))
        }
    }
}


private class ThrottleLimiterStub: ThrottleLimiter {
    private let acquired: Bool

    init(acquired: Bool) {
        self.acquired = acquired
    }

    func tryAcquire() -> Swift.Bool {
        acquired
    }
}