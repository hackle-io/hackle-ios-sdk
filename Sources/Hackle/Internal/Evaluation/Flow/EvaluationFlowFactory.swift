import Foundation

protocol EvaluationFlowFactory {
    func getFlow(experimentType: ExperimentType) -> EvaluationFlow
}

class DefaultEvaluationFlowFactory: EvaluationFlowFactory {

    private let abTestFlow: EvaluationFlow
    private let featureFlagFlow: EvaluationFlow

    init() {

        let targetMatcher = DefaultTargetMatcher(conditionMatcherFactory: DefaultConditionMatcherFactory())
        let actionResolver = DefaultActionResolver(bucketer: DefaultBucketer())
        let overrideResolver = DefaultOverrideResolver(targetMatcher: targetMatcher, actionResolver: actionResolver)

        abTestFlow = DefaultEvaluationFlow.of(
            OverrideEvaluator(overrideResolver: overrideResolver),
            ExperimentTargetEvaluator(experimentTargetDeterminer: DefaultExperimentTargetDeterminer(targetMatcher: targetMatcher)),
            DraftExperimentEvaluator(),
            PausedExperimentEvaluator(),
            CompletedExperimentEvaluator(),
            TrafficAllocateEvaluator(actionResolver: actionResolver)
        )

        featureFlagFlow = DefaultEvaluationFlow.of(
            DraftExperimentEvaluator(),
            PausedExperimentEvaluator(),
            CompletedExperimentEvaluator(),
            OverrideEvaluator(overrideResolver: overrideResolver),
            TargetRuleEvaluator(targetRuleDeterminer: DefaultTargetRuleDeterminer(targetMatcher: targetMatcher), actionResolver: actionResolver),
            DefaultRuleEvaluator(actionResolver: actionResolver)
        )

    }

    func getFlow(experimentType: ExperimentType) -> EvaluationFlow {
        switch experimentType {
        case .abTest: return abTestFlow
        case .featureFlag: return featureFlagFlow
        }
    }
}
