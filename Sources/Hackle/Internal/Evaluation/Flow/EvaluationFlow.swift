import Foundation

protocol EvaluationFlow {
    func evaluate(workspace: Workspace, experiment: Experiment, user: User, defaultVariationKey: Variation.Key) throws -> Evaluation
}

enum DefaultEvaluationFlow: EvaluationFlow {

    case end
    case decision(flowEvaluator: FlowEvaluator, nextFlow: EvaluationFlow)

    func evaluate(workspace: Workspace, experiment: Experiment, user: User, defaultVariationKey: Variation.Key) throws -> Evaluation {
        switch self {
        case .end:
            return Evaluation.of(experiment: experiment, variationKey: defaultVariationKey, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        case .decision(let flowEvaluator, let nextFlow):
            return try flowEvaluator.evaluate(
                workspace: workspace,
                experiment: experiment,
                user: user,
                defaultVariationKey: defaultVariationKey,
                nextFlow: nextFlow
            )
        }
    }

    static func of(_ flowEvaluators: FlowEvaluator...) -> EvaluationFlow {
        var flow: EvaluationFlow = DefaultEvaluationFlow.end
        for flowEvaluator in flowEvaluators.reversed() {
            flow = DefaultEvaluationFlow.decision(flowEvaluator: flowEvaluator, nextFlow: flow)
        }
        return flow
    }
}
