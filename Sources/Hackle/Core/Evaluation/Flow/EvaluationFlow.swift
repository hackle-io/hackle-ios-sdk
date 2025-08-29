import Foundation


class EvaluationFlow<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation> {

    let evaluator: FlowEvaluator?
    let nextFlow: EvaluationFlow<Request, Evaluation>?

    private init(evaluator: FlowEvaluator?, nextFlow: EvaluationFlow<Request, Evaluation>?) {
        self.evaluator = evaluator
        self.nextFlow = nextFlow
    }

    func evaluate(request: Request, context: EvaluatorContext) throws -> Evaluation? {
        guard let evaluator = evaluator, let nextFlow = nextFlow else {
            return nil
        }
        return try evaluator.evaluate(request: request, context: context, nextFlow: nextFlow)
    }

    static func +(lhs: EvaluationFlow<Request, Evaluation>, rhs: EvaluationFlow<Request, Evaluation>) -> EvaluationFlow<Request, Evaluation> {
        guard let evaluator = lhs.evaluator, let nextFlow = lhs.nextFlow else {
            return rhs
        }
        return decision(evaluator: evaluator, nextFlow: nextFlow + rhs)
    }
}

extension EvaluationFlow {

    static func end<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>() -> EvaluationFlow<Request, Evaluation> {
        EvaluationFlow<Request, Evaluation>(evaluator: nil, nextFlow: nil)
    }

    static func decision<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        evaluator: FlowEvaluator,
        nextFlow: EvaluationFlow<Request, Evaluation>
    ) -> EvaluationFlow<Request, Evaluation> {
        EvaluationFlow<Request, Evaluation>(evaluator: evaluator, nextFlow: nextFlow)
    }

    static func of<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        _ evaluators: FlowEvaluator...
    ) -> EvaluationFlow<Request, Evaluation> {
        var flow: EvaluationFlow<Request, Evaluation> = end()
        for evaluator in evaluators.reversed() {
            flow = decision(evaluator: evaluator, nextFlow: flow)
        }
        return flow
    }
}
