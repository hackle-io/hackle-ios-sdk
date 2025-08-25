import Foundation

protocol EvaluationFlowFactory {
    func getExperimentFlow(experimentType: ExperimentType) -> ExperimentFlow
    func getInAppMessageFlow() -> InAppMessageEligibilityFlow
}

class DefaultEvaluationFlowFactory: EvaluationFlowFactory {

    private let abTestFlow: ExperimentFlow
    private let featureFlagFlow: ExperimentFlow
    private let inAppMessageFlow: InAppMessageEligibilityFlow

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

        inAppMessageFlow = InAppMessageEligibilityFlow.of(
            PlatformInAppMessageEligibilityFlowEvaluator(),
            OverrideInAppMessageEligibilityFlowEvaluator(userOverrideMatcher: context.get(InAppMessageUserOverrideMatcher.self)!),
            DraftInAppMessageEligibilityFlowEvaluator(),
            PausedInAppMessageEligibilityFlowEvaluator(),
            PeriodInAppMessageEligibilityFlowEvaluator(),
            TargetInAppMessageEligibilityFlowEvaluator(targetMatcher: context.get(InAppMessageTargetMatcher.self)!),
            FrequencyCapInAppMessageEligibilityFlowEvaluator(frequencyCapMatcher: context.get(InAppMessageFrequencyCapMatcher.self)!),
            HiddenInAppMessageEligibilityFlowEvaluator(hiddenMatcher: context.get(InAppMessageHiddenMatcher.self)!),
            EligibleInAppMessageEligibilityFlowEvaluator()
        )
    }

    func getExperimentFlow(experimentType: ExperimentType) -> ExperimentFlow {
        switch experimentType {
        case .abTest: return abTestFlow
        case .featureFlag: return featureFlagFlow
        }
    }

    func getInAppMessageFlow() -> InAppMessageEligibilityFlow {
        inAppMessageFlow
    }
}
