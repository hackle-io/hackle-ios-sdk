import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageDelayManager: Mock, InAppMessageDelayManager {

    lazy var registerAndDelayMock = MockFunction.throwable(self, registerAndDelay)

    func registerAndDelay(request: InAppMessageScheduleRequest) throws -> InAppMessageDelay {
        return try call(registerAndDelayMock, args: request)
    }

    lazy var delayMock = MockFunction.throwable(self, delay)

    func delay(request: InAppMessageScheduleRequest) throws -> InAppMessageDelay {
        return try call(delayMock, args: request)
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
