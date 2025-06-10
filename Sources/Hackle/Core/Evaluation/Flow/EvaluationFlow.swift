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
}

extension EvaluationFlow {

    static func end<R: EvaluatorRequest, E: EvaluatorEvaluation>() -> EvaluationFlow<R, E> {
        EvaluationFlow<R, E>(evaluator: nil, nextFlow: nil)
    }

    static func decision<R: EvaluatorRequest, E: EvaluatorEvaluation>(
        evaluator: FlowEvaluator,
        nextFlow: EvaluationFlow<R, E>
    ) -> EvaluationFlow<R, E> {
        EvaluationFlow<R, E>(evaluator: evaluator, nextFlow: nextFlow)
    }

    static func of<R: EvaluatorRequest, E: EvaluatorEvaluation>(
        _ evaluators: FlowEvaluator...
    ) -> EvaluationFlow<R, E> {
        var flow: EvaluationFlow<R, E> = end()
        for evaluator in evaluators.reversed() {
            flow = decision(evaluator: evaluator, nextFlow: flow)
        }
        return flow
    }
}
