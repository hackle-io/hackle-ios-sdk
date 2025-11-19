import Foundation

protocol InAppMessageEligibilityFlowFactory {
    func triggerFlow() -> InAppMessageEligibilityFlow
    func deliverFlow(reEvaluate: Bool) -> InAppMessageEligibilityFlow
}

class DefaultInAppMessageEligibilityFlowFactory: InAppMessageEligibilityFlowFactory {

    private let _triggerFlow: InAppMessageEligibilityFlow
    private let _deliverFlow: InAppMessageEligibilityFlow
    private let _deliverReEvalutateFlow: InAppMessageEligibilityFlow

    init(context: EvaluationContext, layoutEvaluator: Evaluator) {
        let evaluateFlow: InAppMessageEligibilityFlow = InAppMessageEligibilityFlow.of(
            PlatformInAppMessageEligibilityFlowEvaluator(),
            OverrideInAppMessageEligibilityFlowEvaluator(userOverrideMatcher: context.get(InAppMessageUserOverrideMatcher.self)!),
            DraftInAppMessageEligibilityFlowEvaluator(),
            PausedInAppMessageEligibilityFlowEvaluator(),
            PeriodInAppMessageEligibilityFlowEvaluator(),
            TimetableInAppMessageEligibilityFlowEvaluator(),
            TargetInAppMessageEligibilityFlowEvaluator(targetMatcher: context.get(InAppMessageTargetMatcher.self)!)
        )

        let layoutFlow: InAppMessageEligibilityFlow = InAppMessageEligibilityFlow.of(
            LayoutResolveInAppMessageEligibilityFlowEvaluator(layoutEvaluator: layoutEvaluator)
        )

        let dedupFlow: InAppMessageEligibilityFlow = InAppMessageEligibilityFlow.of(
            FrequencyCapInAppMessageEligibilityFlowEvaluator(frequencyCapMatcher: context.get(InAppMessageFrequencyCapMatcher.self)!),
            HiddenInAppMessageEligibilityFlowEvaluator(hiddenMatcher: context.get(InAppMessageHiddenMatcher.self)!)
        )

        let eligibleFlow: InAppMessageEligibilityFlow = InAppMessageEligibilityFlow.of(
            EligibleInAppMessageEligibilityFlowEvaluator()
        )

        _triggerFlow = evaluateFlow + layoutFlow + dedupFlow + eligibleFlow
        _deliverFlow = dedupFlow + eligibleFlow
        _deliverReEvalutateFlow = evaluateFlow + dedupFlow + eligibleFlow
    }

    func triggerFlow() -> InAppMessageEligibilityFlow {
        return _triggerFlow
    }

    func deliverFlow(reEvaluate: Bool) -> InAppMessageEligibilityFlow {
        if reEvaluate {
            return _deliverReEvalutateFlow
        } else {
            return _deliverFlow
        }
    }
}
