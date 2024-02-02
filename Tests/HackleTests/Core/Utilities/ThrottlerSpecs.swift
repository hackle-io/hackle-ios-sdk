import Foundation
import Quick
import Nimble
@testable import Hackle

class ThrottlerSpecs: QuickSpec {
    let semaphore = DispatchSemaphore(value: 0)
    let queue = DispatchQueue(label: "")
    
    override func spec() {
        it("not throttle after interval seconds later") {
            DispatchQueue.global(qos: .background).async {
                let throttler = Throttler(intervalInSeconds: 1, dispatchQueue: self.queue)
                var throttledHistories: [Bool] = []
                throttler.execute(
                    action: { throttledHistories.append(false) },
                    throttled: { throttledHistories.append(true) }
                )
                throttler.execute(
                    action: { throttledHistories.append(false) },
                    throttled: { throttledHistories.append(true) }
                )
                sleep(1)
                throttler.execute(
                    action: { throttledHistories.append(false) },
                    throttled: { throttledHistories.append(true) }
                )
                expect(throttledHistories) == [false, true, false]
                self.semaphore.signal()
            }
            self.semaphore.wait()
        }
        it("throttle more than 2 limits") {
            DispatchQueue.global(qos: .background).async {
                let throttler = Throttler(intervalInSeconds: 1, dispatchQueue: self.queue, limitInScope: 2)
                var throttledHistories: [Bool] = []
                throttler.execute(
                    action: { throttledHistories.append(false) },
                    throttled: { throttledHistories.append(true) }
                )
                throttler.execute(
                    action: { throttledHistories.append(false) },
                    throttled: { throttledHistories.append(true) }
                )
                throttler.execute(
                    action: { throttledHistories.append(false) },
                    throttled: { throttledHistories.append(true) }
                )
                sleep(1)
                throttler.execute(
                    action: { throttledHistories.append(false) },
                    throttled: { throttledHistories.append(true) }
                )
                expect(throttledHistories) == [false, false, true, false]
                self.semaphore.signal()
            }
            self.semaphore.wait()
        }
    }
}
