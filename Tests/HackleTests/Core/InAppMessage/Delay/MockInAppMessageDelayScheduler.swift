import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageDelayScheduler: Mock, InAppMessageDelayScheduler {

    lazy var scheduleMock = MockFunction(self, schedule)

    func schedule(delay: InAppMessageDelay) -> InAppMessageDelayTask {
        return call(scheduleMock, args: delay)
    }
}
