import Foundation
import Mockery
@testable import Hackle

class MockFlowEvaluator: Mock, FlowEvaluator {

    lazy var evaluateMock = MockFunction(self, evaluate)

    func evaluate(workspace: Workspace, experiment: Experiment, user: HackleUser, defaultVariationKey: Variation.Key, nextFlow: EvaluationFlow) throws -> Evaluation {
        call(evaluateMock, args: (workspace, experiment, user, defaultVariationKey, nextFlow))
    }
}