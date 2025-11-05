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

    static func end<Req: EvaluatorRequest, Eval: EvaluatorEvaluation>() -> EvaluationFlow<Req, Eval> {
        EvaluationFlow<Req, Eval>(evaluator: nil, nextFlow: nil)
    }

    static func decision<Req: EvaluatorRequest, Eval: EvaluatorEvaluation>(
        evaluator: FlowEvaluator,
        nextFlow: EvaluationFlow<Req, Eval>
    ) -> EvaluationFlow<Req, Eval> {
        EvaluationFlow<Req, Eval>(evaluator: evaluator, nextFlow: nextFlow)
    }

    static func of<Req: EvaluatorRequest, Eval: EvaluatorEvaluation>(
        _ evaluators: FlowEvaluator...
    ) -> EvaluationFlow<Req, Eval> {
        var flow: EvaluationFlow<Req, Eval> = end()
        for evaluator in evaluators.reversed() {
            flow = decision(evaluator: evaluator, nextFlow: flow)
        }
        return flow
    }
}
