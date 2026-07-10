import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageScheduleProcessor: Mock, InAppMessageScheduleProcessor {
    // MockFunction은 sync 함수 타입만 받으므로, async 프로토콜 메서드 대신 sync stub으로 참조를 만든다(MockUserManager 관례와 동일).
    lazy var processMock = MockFunction(self, processStub)

    private func processStub(request: InAppMessageScheduleRequest) -> InAppMessageScheduleResponse {
        fatalError("processStub is not invoked directly; it only exists to type the MockFunction reference")
    }

    func process(request: InAppMessageScheduleRequest) async -> InAppMessageScheduleResponse {
        return call(processMock, args: request)
    }
}
