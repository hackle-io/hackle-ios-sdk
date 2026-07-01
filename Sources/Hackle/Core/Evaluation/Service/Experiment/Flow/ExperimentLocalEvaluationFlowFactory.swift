import Foundation

class ExperimentLocalEvaluationFlowFactory {

    private let abTestFlow: ExperimentLocalEvaluationFlow
    private let featureFlagFlow: ExperimentLocalEvaluationFlow

    init(targetMatcher: TargetMatcher, bucketer: Bucketer, overrideStorage: ManualOverrideStorage) {
        let actionResolver = DefaultActionResolver(bucketer: bucketer)
        let overrideResolver = DefaultOverrideResolver(manualOverrideStorage: overrideStorage, targetMatcher: targetMatcher, actionResolver: actionResolver)

        abTestFlow = ExperimentLocalEvaluationFlow.of(
            OverrideExperimentLocalFlowEvaluator(overrideResolver: overrideResolver),
            IdentifierExperimentLocalFlowEvaluator(),
            ContainerExperimentLocalFlowEvaluator(containerResolver: DefaultContainerResolver(bucketer: bucketer)),
            TargetExperimentLocalFlowEvaluator(experimentTargetDeterminer: DefaultExperimentTargetDeterminer(targetMatcher: targetMatcher)),
            DraftExperimentLocalFlowEvaluator(),
            PausedExperimentLocalFlowEvaluator(),
            CompletedExperimentLocalFlowEvaluator(),
            TrafficAllocateExperimentLocalFlowEvaluator(actionResolver: actionResolver)
        )

        featureFlagFlow = ExperimentLocalEvaluationFlow.of(
            DraftExperimentLocalFlowEvaluator(),
            PausedExperimentLocalFlowEvaluator(),
            CompletedExperimentLocalFlowEvaluator(),
            OverrideExperimentLocalFlowEvaluator(overrideResolver: overrideResolver),
            IdentifierExperimentLocalFlowEvaluator(),
            TargetRuleExperimentLocalFlowEvaluator(targetRuleDeterminer: DefaultExperimentTargetRuleDeterminer(targetMatcher: targetMatcher), actionResolver: actionResolver),
            DefaultRuleExperimentLocalFlowEvaluator(actionResolver: actionResolver)
        )
    }

    func flow(experimentType: ExperimentType) -> ExperimentLocalEvaluationFlow {
        switch experimentType {
        case .abTest: return abTestFlow
        case .featureFlag: return featureFlagFlow
        }
    }
}
