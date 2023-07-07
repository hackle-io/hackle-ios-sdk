import Foundation

protocol EvaluationFlowFactory {
    func getExperimentFlow(experimentType: ExperimentType) -> ExperimentFlow
    func getInAppMessageFlow() -> InAppMessageFlow
}

class DefaultEvaluationFlowFactory: EvaluationFlowFactory {

    private let abTestFlow: ExperimentFlow
    private let featureFlagFlow: ExperimentFlow
    private let inAppMessageFlow: InAppMessageFlow

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

        let inAppMessageResolver = context.get(InAppMessageResolver.self)!

        inAppMessageFlow = InAppMessageFlow.of(
            PlatformInAppMessageFlowEvaluator(),
            OverrideInAppMessageFlowEvaluator(userOverrideMatcher: context.get(InAppMessageUserOverrideMatcher.self)!, inAppMessageResolver: inAppMessageResolver),
            DraftInAppMessageFlowEvaluator(),
            PausedInAppMessageFlowEvaluator(),
            PeriodInAppMessageFlowEvaluator(),
            HiddenInAppMessageFlowEvaluator(hiddenMatcher: context.get(InAppMessageHiddenMatcher.self)!),
            TargetInAppMessageFlowEvaluator(targetMatcher: context.get(InAppMessageTargetMatcher.self)!, inAppMessageResolver: inAppMessageResolver)
        )
    }

    func getExperimentFlow(experimentType: ExperimentType) -> ExperimentFlow {
        switch experimentType {
        case .abTest: return abTestFlow
        case .featureFlag: return featureFlagFlow
        }
    }

    func getInAppMessageFlow() -> InAppMessageFlow {
        inAppMessageFlow
    }
}
