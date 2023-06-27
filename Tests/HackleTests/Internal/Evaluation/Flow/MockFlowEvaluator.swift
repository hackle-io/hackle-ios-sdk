import Foundation
import Mockery
@testable import Hackle

class FlowEvaluatorStub: FlowEvaluator {

    private let evaluation: EvaluatorEvaluation

    init(evaluation: EvaluatorEvaluation) {
        self.evaluation = evaluation
    }

    func evaluate<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, Evaluation>
    ) throws -> Evaluation? {
        evaluation as? Evaluation
    }
}


class NextFlowEvaluator: FlowEvaluator {
    var callCount = 0

    func evaluate<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, Evaluation>
    ) throws -> Evaluation? {
        callCount += 1
        return try nextFlow.evaluate(request: request, context: context)
    }
}