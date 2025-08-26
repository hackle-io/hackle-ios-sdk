import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageEvaluator: Mock, InAppMessageEvaluator {
    lazy var evaluateMock = MockFunction(self, evaluate)

    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser, timestamp: Date) throws -> InAppMessageEvaluation {
        return call(evaluateMock, args: (workspace, inAppMessage, user, timestamp))
    }
}
