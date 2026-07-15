import Foundation

enum ExperimentReference {
    static func resolve(sourceRequest: EvaluateRequest, evaluation: ExperimentEvaluation) -> ExperimentEvaluation {
        if sourceRequest is ExperimentEvaluateRequest,
           evaluation.experiment.type == .abTest,
           evaluation.experimentResult.reason == DecisionReason.TRAFFIC_ALLOCATED {
            return ExperimentEvaluation(
                entity: evaluation.experiment,
                result: evaluation.experimentResult.with(reason: DecisionReason.TRAFFIC_ALLOCATED_BY_TARGETING)
            )
        }
        return evaluation
    }
}
