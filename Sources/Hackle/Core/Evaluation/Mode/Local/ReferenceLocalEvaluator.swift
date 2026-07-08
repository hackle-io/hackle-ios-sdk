import Foundation

protocol ReferenceLocalEvaluator {

    associatedtype Reference
    associatedtype ReferenceEvaluation: Evaluation

    func cachedEvaluation(context: EvaluatorContext, reference: Reference) -> ReferenceEvaluation?

    func doEvaluate(sourceRequest: LocalEvaluateRequest, context: EvaluatorContext, reference: Reference) throws -> ReferenceEvaluation
}

extension ReferenceLocalEvaluator {

    func evaluate(sourceRequest: LocalEvaluateRequest, context: EvaluatorContext, reference: Reference) throws -> ReferenceEvaluation {
        if let evaluation = cachedEvaluation(context: context, reference: reference) {
            return evaluation
        }

        let evaluation = try doEvaluate(sourceRequest: sourceRequest, context: context, reference: reference)
        context.add(evaluation)
        return evaluation
    }
}
