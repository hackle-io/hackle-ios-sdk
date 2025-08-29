import Foundation

protocol InAppMessageEvaluator: ContextualEvaluator where Request: InAppMessageEvaluatorRequest, Evaluation: InAppMessageEvaluatorEvaluation {
    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation
    func recordInternal(request: Request, evaluation: Evaluation)
}

extension InAppMessageEvaluator {
    func record(request: InAppMessageEvaluatorRequest, evaluation: InAppMessageEvaluatorEvaluation) {
        recordInternal(request: request as! Self.Request, evaluation: evaluation as! Self.Evaluation)
    }
}
