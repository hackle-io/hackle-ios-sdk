import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockEvaluator: Mock, Evaluator {
    lazy var evaluateMock = MockFunction(self, evaluate)

    func evaluate(workspace: Workspace, experiment: Experiment, user: User, defaultVariationKey: Variation.Key) throws -> Evaluation {
        call(evaluateMock, args: (workspace, experiment, user, defaultVariationKey))
    }
}