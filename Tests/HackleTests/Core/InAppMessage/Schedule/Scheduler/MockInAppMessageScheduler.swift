import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageScheduler: Mock, InAppMessageScheduler {
    lazy var supportMock = MockFunction(self, support)

    func support(scheduleType: InAppMessageScheduleType) -> Bool {
        return call(supportMock, args: scheduleType)
    }

    // MockFunction은 sync 함수 타입만 받으므로, async 프로토콜 메서드는 sync stub으로 참조를 만든다.
    lazy var deliverMock = MockFunction.throwable(self, deliverStub)

    private func deliverStub(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        fatalError("deliverStub is not invoked directly; it only exists to type the MockFunction reference")
    }

    func deliver(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse {
        return try call(deliverMock, args: request)
    }

    lazy var delayMock = MockFunction.throwable(self, delayStub)

    private func delayStub(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        fatalError("delayStub is not invoked directly; it only exists to type the MockFunction reference")
    }

    func delay(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse {
        return try call(delayMock, args: request)
    }

    lazy var ignoreMock = MockFunction.throwable(self, ignoreStub)

    private func ignoreStub(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        fatalError("ignoreStub is not invoked directly; it only exists to type the MockFunction reference")
    }

    func ignore(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse {
        return try call(ignoreMock, args: request)
    }
}
