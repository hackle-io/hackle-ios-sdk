import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageEvaluator: Mock, InAppMessageEvaluator {
    lazy var evaluateMock = MockFunction.throwable(self, evaluate)

    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser, timestamp: Date) throws -> InAppMessageEvaluation {
        return try call(evaluateMock, args: (workspace, inAppMessage, user, timestamp))
    }
}
