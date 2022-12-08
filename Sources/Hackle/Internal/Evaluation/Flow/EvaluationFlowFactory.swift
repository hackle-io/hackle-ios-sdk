import Foundation

protocol EvaluationFlowFactory {
    var remoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer { get }
    func getFlow(experimentType: ExperimentType) -> EvaluationFlow
}

class DefaultEvaluationFlowFactory: EvaluationFlowFactory {

    private let abTestFlow: EvaluationFlow
    private let featureFlagFlow: EvaluationFlow
    let remoteConfigTargetRuleDeterminer: RemoteConfigTargetRuleDeterminer

    init() {

        let bucketer = DefaultBucketer()
        let targetMatcher = DefaultTargetMatcher(conditionMatcherFactory: DefaultConditionMatcherFactory())
        let actionResolver = DefaultActionResolver(bucketer: bucketer)
        let overrideResolver = DefaultOverrideResolver(targetMatcher: targetMatcher, actionResolver: actionResolver)
        let containerResolver = DefaultContainerResolver(bucketer: bucketer)

        abTestFlow = DefaultEvaluationFlow.of(
            OverrideEvaluator(overrideResolver: overrideResolver),
            IdentifierEvaluator(),
            ContainerEvaluator(containerResolver: containerResolver),
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
            IdentifierEvaluator(),
            TargetRuleEvaluator(targetRuleDeterminer: DefaultExperimentTargetRuleDeterminer(targetMatcher: targetMatcher), actionResolver: actionResolver),
            DefaultRuleEvaluator(actionResolver: actionResolver)
        )

        remoteConfigTargetRuleDeterminer = DefaultRemoteConfigTargetRuleDeterminer(
            matcher: DefaultRemoteConfigTargetRuleMatcher(targetMatcher: targetMatcher, buckter: bucketer)
        )
    }

    func getFlow(experimentType: ExperimentType) -> EvaluationFlow {
        switch experimentType {
        case .abTest: return abTestFlow
        case .featureFlag: return featureFlagFlow
        }
    }
}
