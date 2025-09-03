import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageDelayManager: Mock, InAppMessageDelayManager {

    lazy var registerAndDelayMock = MockFunction(self, registerAndDelay)

    func registerAndDelay(request: InAppMessageScheduleRequest) -> InAppMessageDelay {
        return call(registerAndDelayMock, args: request)
    }

    lazy var delayMock = MockFunction(self, delay)

    func delay(request: InAppMessageScheduleRequest) -> InAppMessageDelay {
        return call(delayMock, args: request)
    }

    lazy var deleteMock = MockFunction(self, delete)

    func delete(request: InAppMessageScheduleRequest) -> InAppMessageDelay? {
        return call(deleteMock, args: request)
    }

    lazy var cancelAllMock = MockFunction(self, cancelAll)

    func cancelAll() -> [InAppMessageDelay] {
        return call(cancelAllMock, args: ())
    }
}
