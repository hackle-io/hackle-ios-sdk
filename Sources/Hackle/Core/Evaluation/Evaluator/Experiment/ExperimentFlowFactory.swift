import Foundation

protocol ExperimentFlowFactory {
    func get(experimentType: ExperimentType) -> ExperimentFlow
}

class DefaultExperimentFlowFactory: ExperimentFlowFactory {

    private let abTestFlow: ExperimentFlow
    private let featureFlagFlow: ExperimentFlow

    init(context: EvaluationContext) {
        let experimentActionResolver = context.get(ActionResolver.self)!

        abTestFlow = ExperimentFlow.of(
            OverrideEvaluator(overrideResolver: context.get(OverrideResolver.self)!),
            IdentifierEvaluator(),
            ContainerEvaluator(containerResolver: context.get(ContainerResolver.self)!),
            ExperimentTargetEvaluator(experimentTargetDeterminer: context.get(ExperimentTargetDeterminer.self)!),
            DraftExperimentEvaluator(),
            PausedExperimentEvaluator(),
            CompletedExperimentEvaluator(),
            TrafficAllocateEvaluator(actionResolver: experimentActionResolver)
        )

        featureFlagFlow = ExperimentFlow.of(
            DraftExperimentEvaluator(),
            PausedExperimentEvaluator(),
            CompletedExperimentEvaluator(),
            OverrideEvaluator(overrideResolver: context.get(OverrideResolver.self)!),
            IdentifierEvaluator(),
            TargetRuleEvaluator(targetRuleDeterminer: context.get(ExperimentTargetRuleDeterminer.self)!, actionResolver: experimentActionResolver),
            DefaultRuleEvaluator(actionResolver: context.get(ActionResolver.self)!)
        )
    }

    func get(experimentType: ExperimentType) -> ExperimentFlow {
        switch experimentType {
        case .abTest: return abTestFlow
        case .featureFlag: return featureFlagFlow
        }
    }
}
