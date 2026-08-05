import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessagePresentProcessor: Mock, InAppMessagePresentProcessor {
    // MockFunction은 sync 함수 타입만 받으므로, async 프로토콜 메서드는 sync stub으로 참조를 만든다.
    lazy var processMock = MockFunction(self, processStub)

    private func processStub(request: InAppMessagePresentRequest) -> InAppMessagePresentResponse {
        fatalError("processStub is not invoked directly; it only exists to type the MockFunction reference")
    }

    func process(request: InAppMessagePresentRequest) async -> InAppMessagePresentResponse {
        call(processMock, args: request)
    }
}
