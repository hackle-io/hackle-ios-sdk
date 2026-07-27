import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageScheduleProcessor: Mock, InAppMessageScheduleProcessor {
    // MockFunction은 sync 함수 타입만 받으므로, async 프로토콜 메서드는 sync stub으로 참조를 만든다.
    lazy var processMock = MockFunction(self, processStub)

    private func processStub(request: InAppMessageScheduleRequest) -> InAppMessageScheduleResponse {
        fatalError("processStub is not invoked directly; it only exists to type the MockFunction reference")
    }

    func process(request: InAppMessageScheduleRequest) async -> InAppMessageScheduleResponse {
        return call(processMock, args: request)
    }

    lazy var processAsyncMock = MockFunction(self, processAsync)

    func processAsync(request: InAppMessageScheduleRequest) {
        call(processAsyncMock, args: request)
    }
}
