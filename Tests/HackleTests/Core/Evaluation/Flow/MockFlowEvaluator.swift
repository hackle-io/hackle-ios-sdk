import Foundation
import MockingKit
@testable import Hackle

class FlowEvaluatorStub: FlowEvaluator {

    private let evaluation: Evaluation

    init(evaluation: Evaluation) {
        self.evaluation = evaluation
    }

    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        evaluation as? E
    }
}


class NextFlowEvaluator: FlowEvaluator {
    var callCount = 0

    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E? {
        callCount += 1
        return try nextFlow.evaluate(request: request, context: context)
    }
}
