import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageDeliverEvaluator: Mock, InAppMessageDeliverEvaluator {
    lazy var evaluateMock = MockFunction.throwable(self, evaluate)

    func evaluate(request: InAppMessageDeliverRequest, user: HackleUser) throws -> InAppMessageDeliverEvaluateResponse {
        try call(evaluateMock, args: (request, user))
    }
}
