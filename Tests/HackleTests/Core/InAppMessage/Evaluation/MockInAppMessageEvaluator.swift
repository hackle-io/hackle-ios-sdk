import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageEvaluator: Mock, InAppMessageEvaluator {
    lazy var evaluateMock = MockFunction.throwable(self, evaluate)

    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser, timestamp: Date) throws -> InAppMessageEvaluation {
        return try call(evaluateMock, args: (workspace, inAppMessage, user, timestamp))
    }
}

class InAppMessageEvaluatorStub: InAppMessageEvaluator {

    var evaluations: [InAppMessageEvaluation] {
        didSet {
            count = 0
        }
    }

    var count = 0

    init(evaluations: [InAppMessageEvaluation] = []) {
        self.evaluations = evaluations
    }

    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, user: HackleUser, timestamp: Date) throws -> InAppMessageEvaluation {
        let evaluation = evaluations[count]
        count += 1
        return evaluation
    }
}
