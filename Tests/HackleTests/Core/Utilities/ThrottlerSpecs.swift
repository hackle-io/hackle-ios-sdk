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
                throttler { throttle, quotesInScope, leftTimeIntervalInScope in
                    expect(throttle) == false
                }
                throttler { throttle, quotesInScope, leftTimeIntervalInScope in
                    expect(throttle) == true
                }
                sleep(1)
                throttler { throttle, quotesInScope, leftTimeIntervalInScope in
                    expect(throttle) == false
                }
                sleep(1)
                self.semaphore.signal()
            }
            self.semaphore.wait()
        }
        it("throttle more than 1 limits") {
            DispatchQueue.global(qos: .background).async {
                let throttler = Throttler(intervalInSeconds: 1, limitInScope: 2, dispatchQueue: self.queue)
                throttler { throttle, quotesInScope, leftTimeIntervalInScope in
                    expect(throttle) == false
                }
                throttler { throttle, quotesInScope, leftTimeIntervalInScope in
                    expect(throttle) == false
                }
                throttler { throttle, quotesInScope, leftTimeIntervalInScope in
                    expect(throttle) == true
                }
                sleep(1)
                throttler { throttle, quotesInScope, leftTimeIntervalInScope in
                    expect(throttle) == false
                }
                sleep(1)
                self.semaphore.signal()
            }
            self.semaphore.wait()
        }
    }
}
