import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageScheduler: Mock, InAppMessageScheduler {
    lazy var supportMock = MockFunction(self, support)

    func support(scheduleType: InAppMessageScheduleType) -> Bool {
        return call(supportMock, args: scheduleType)
    }

    lazy var deliverMock = MockFunction.throwable(self, deliver)

    func deliver(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        return try call(deliverMock, args: request)
    }

    lazy var delayMock = MockFunction.throwable(self, delay)

    func delay(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        return try call(delayMock, args: request)
    }

    lazy var ignoreMock = MockFunction.throwable(self, ignore)

    func ignore(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        return try call(ignoreMock, args: request)
    }
}
