import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageDeliverEvaluator: Mock, InAppMessageDeliverEvaluator {
    // MockFunction은 sync 함수 타입만 받으므로, async 프로토콜 메서드는 sync stub으로 참조를 만든다.
    lazy var evaluateMock = MockFunction.throwable(self, evaluateStub)

    private func evaluateStub(request: InAppMessageDeliverRequest, user: HackleUser) throws -> InAppMessageDeliverEvaluateResponse {
        fatalError("evaluateStub is not invoked directly; it only exists to type the MockFunction reference")
    }

    func evaluate(request: InAppMessageDeliverRequest, user: HackleUser) async throws -> InAppMessageDeliverEvaluateResponse {
        try call(evaluateMock, args: (request, user))
    }
}
