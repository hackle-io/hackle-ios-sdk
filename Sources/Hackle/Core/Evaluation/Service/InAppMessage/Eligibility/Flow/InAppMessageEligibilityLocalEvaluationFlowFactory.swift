import Foundation

protocol InAppMessageEligibilityLocalEvaluationFlowFactory {
    func get(request: InAppMessageEligibilityLocalEvaluateRequest) -> InAppMessageEligibilityLocalEvaluationFlow
}

class DefaultInAppMessageEligibilityLocalEvaluationFlowFactory: InAppMessageEligibilityLocalEvaluationFlowFactory {

    private let overrideFlow: InAppMessageEligibilityLocalEvaluationFlow
    private let triggerFlow: InAppMessageEligibilityLocalEvaluationFlow
    private let deliverFlow: InAppMessageEligibilityLocalEvaluationFlow
    private let deliverReEvaluateFlow: InAppMessageEligibilityLocalEvaluationFlow

    init(
        targetMatcher: TargetMatcher,
        impressionStorage: InAppMessageImpressionStorage,
        hiddenStorage: InAppMessageHiddenStorage,
        layoutEvaluator: InAppMessageLayoutLocalEvaluator
    ) {
        let overrideFlow: InAppMessageEligibilityLocalEvaluationFlow = InAppMessageEligibilityLocalEvaluationFlow.of(
            OverrideInAppMessageEligibilityLocalFlowEvaluator(userOverrideMatcher: InAppMessageUserOverrideMatcher())
        )

        let evaluateFlow: InAppMessageEligibilityLocalEvaluationFlow = InAppMessageEligibilityLocalEvaluationFlow.of(
            PlatformInAppMessageEligibilityLocalFlowEvaluator(),
            OverrideInAppMessageEligibilityLocalFlowEvaluator(userOverrideMatcher: InAppMessageUserOverrideMatcher()),
            DraftInAppMessageEligibilityLocalFlowEvaluator(),
            PauseInAppMessageEligibilityLocalFlowEvaluator(),
            PeriodInAppMessageEligibilityFlowEvaluator(),
            TimetableInAppMessageEligibilityFlowEvaluator(),
            TargetInAppMessageEligibilityLocalFlowEvaluator(targetMatcher: InAppMessageTargetMatcher(targetMatcher: targetMatcher))
        )

        let layoutFlow: InAppMessageEligibilityLocalEvaluationFlow = InAppMessageEligibilityLocalEvaluationFlow.of(
            LayoutResolveInAppMessageEligibilityLocalFlowEvaluator(layoutEvaluator: layoutEvaluator)
        )

        let deduplicateFlow: InAppMessageEligibilityLocalEvaluationFlow = InAppMessageEligibilityLocalEvaluationFlow.of(
            FrequencyCapInAppMessageEligibilityFlowEvaluator(frequencyCapMatcher: InAppMessageFrequencyCapMatcher(storage: impressionStorage)),
            HiddenInAppMessageEligibilityFlowEvaluator(hiddenMatcher: InAppMessageHiddenMatcher(storage: hiddenStorage))
        )

        let eligibleFlow: InAppMessageEligibilityLocalEvaluationFlow = InAppMessageEligibilityLocalEvaluationFlow.of(
            EligibleInAppMessageEligibilityFlowEvaluator()
        )

        self.overrideFlow = overrideFlow
        self.triggerFlow = evaluateFlow + layoutFlow + deduplicateFlow + eligibleFlow
        self.deliverFlow = overrideFlow + deduplicateFlow + eligibleFlow
        self.deliverReEvaluateFlow = evaluateFlow + deduplicateFlow + eligibleFlow
    }

    func get(request: InAppMessageEligibilityLocalEvaluateRequest) -> InAppMessageEligibilityLocalEvaluationFlow {
        switch request.scope {
        case .trigger:
            return triggerFlow
        case .deliver:
            return request.inAppMessage.evaluateContext.atDeliverTime ? deliverReEvaluateFlow : deliverFlow
        }
    }
}
