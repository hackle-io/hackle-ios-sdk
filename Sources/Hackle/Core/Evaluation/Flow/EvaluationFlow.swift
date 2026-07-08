import Foundation


class EvaluationFlow<Request: EvaluateRequest, E: Evaluation> {

    let evaluator: FlowEvaluator?
    let nextFlow: EvaluationFlow<Request, E>?

    private init(evaluator: FlowEvaluator?, nextFlow: EvaluationFlow<Request, E>?) {
        self.evaluator = evaluator
        self.nextFlow = nextFlow
    }

    func evaluate(request: Request, context: EvaluatorContext) throws -> E? {
        guard let evaluator = evaluator, let nextFlow = nextFlow else {
            return nil
        }
        return try evaluator.evaluate(request: request, context: context, nextFlow: nextFlow)
    }

    static func +(lhs: EvaluationFlow<Request, E>, rhs: EvaluationFlow<Request, E>) -> EvaluationFlow<Request, E> {
        guard let evaluator = lhs.evaluator, let nextFlow = lhs.nextFlow else {
            return rhs
        }
        return decision(evaluator: evaluator, nextFlow: nextFlow + rhs)
    }
}

extension EvaluationFlow {

    static func end<Req: EvaluateRequest, Eval: Evaluation>() -> EvaluationFlow<Req, Eval> {
        EvaluationFlow<Req, Eval>(evaluator: nil, nextFlow: nil)
    }

    static func decision<Req: EvaluateRequest, Eval: Evaluation>(
        evaluator: FlowEvaluator,
        nextFlow: EvaluationFlow<Req, Eval>
    ) -> EvaluationFlow<Req, Eval> {
        EvaluationFlow<Req, Eval>(evaluator: evaluator, nextFlow: nextFlow)
    }

    static func of<Req: EvaluateRequest, Eval: Evaluation>(
        _ evaluators: FlowEvaluator...
    ) -> EvaluationFlow<Req, Eval> {
        var flow: EvaluationFlow<Req, Eval> = end()
        for evaluator in evaluators.reversed() {
            flow = decision(evaluator: evaluator, nextFlow: flow)
        }
        return flow
    }
}
