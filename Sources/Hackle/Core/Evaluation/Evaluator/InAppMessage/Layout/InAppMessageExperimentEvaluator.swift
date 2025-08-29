import Foundation

class InAppMessageExperimentEvaluator: ExperimentContextualEvaluator {

    let evaluator: Evaluator

    init(evaluator: Evaluator) {
        self.evaluator = evaluator
    }

    func resolve(request: EvaluatorRequest, context: EvaluatorContext, evaluation: ExperimentEvaluation) throws -> ExperimentEvaluation {
        context.setProperty("experiment_id", evaluation.experiment.id)
        context.setProperty("experiment_key", evaluation.experiment.key)
        context.setProperty("variation_id", evaluation.variationId)
        context.setProperty("variation_key", evaluation.variationKey)
        context.setProperty("experiment_decision_reason", evaluation.reason)
        return evaluation
    }
}