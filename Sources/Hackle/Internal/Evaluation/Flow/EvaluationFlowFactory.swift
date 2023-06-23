import Foundation

protocol EvaluationFlowFactory {
    func getFlow(experimentType: ExperimentType) -> EvaluationFlow
}

class DefaultEvaluationFlowFactory: EvaluationFlowFactory {

    private let abTestFlow: EvaluationFlow
    private let featureFlagFlow: EvaluationFlow

    init(context: EvaluationContext) {
        abTestFlow = DefaultEvaluationFlow.of(
            OverrideEvaluator(overrideResolver: context.get(OverrideResolver.self)!),
            IdentifierEvaluator(),
            ContainerEvaluator(containerResolver: context.get(ContainerResolver.self)!),
            ExperimentTargetEvaluator(experimentTargetDeterminer: context.get(ExperimentTargetDeterminer.self)!),
            DraftExperimentEvaluator(),
            PausedExperimentEvaluator(),
            CompletedExperimentEvaluator(),
            TrafficAllocateEvaluator(actionResolver: context.get(ActionResolver.self)!)
        )

        featureFlagFlow = DefaultEvaluationFlow.of(
            DraftExperimentEvaluator(),
            PausedExperimentEvaluator(),
            CompletedExperimentEvaluator(),
            OverrideEvaluator(overrideResolver: context.get(OverrideResolver.self)!),
            IdentifierEvaluator(),
            TargetRuleEvaluator(targetRuleDeterminer: context.get(ExperimentTargetRuleDeterminer.self)!, actionResolver: context.get(ActionResolver.self)!),
            DefaultRuleEvaluator(actionResolver: context.get(ActionResolver.self)!)
        )
    }

    func getFlow(experimentType: ExperimentType) -> EvaluationFlow {
        switch experimentType {
        case .abTest: return abTestFlow
        case .featureFlag: return featureFlagFlow
        }
    }
}
