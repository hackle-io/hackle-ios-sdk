import Foundation
import Mockery
@testable import Hackle

class MockFlowEvaluator: Mock, FlowEvaluator {

    lazy var evaluateMock = MockFunction(self, evaluate)

    func evaluate(request: ExperimentRequest, context: EvaluatorContext, nextFlow: EvaluationFlow) throws -> ExperimentEvaluation {
        call(evaluateMock, args: (request, context, nextFlow))
    }
}