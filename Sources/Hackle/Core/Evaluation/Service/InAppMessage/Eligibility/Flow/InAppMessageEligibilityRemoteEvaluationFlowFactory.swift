import Foundation

protocol InAppMessageEligibilityRemoteEvaluationFlowFactory {
    func get(request: InAppMessageEligibilityRemoteEvaluateRequest) -> InAppMessageEligibilityRemoteEvaluationFlow
}

class DefaultInAppMessageEligibilityRemoteEvaluationFlowFactory: InAppMessageEligibilityRemoteEvaluationFlowFactory {

    private let triggerFlow: InAppMessageEligibilityRemoteEvaluationFlow
    private let deliverFlow: InAppMessageEligibilityRemoteEvaluationFlow
    private let deliverReEvaluationFlow: InAppMessageEligibilityRemoteEvaluationFlow

    init(
        impressionStorage: InAppMessageImpressionStorage,
        hiddenStorage: InAppMessageHiddenStorage,
        layoutEvaluator: InAppMessageLayoutRemoteEvaluator
    ) {
        let overrideFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            OverrideInAppMessageEligibilityRemoteFlowEvaluator()
        )

        let evaluationFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            PlatformInAppMessageEligibilityRemoteFlowEvaluator(),
            OverrideInAppMessageEligibilityRemoteFlowEvaluator(),
            IneligibleInAppMessageEligibilityRemoteFlowEvaluator(),
            PeriodInAppMessageEligibilityFlowEvaluator(),
            TimetableInAppMessageEligibilityFlowEvaluator()
        )

        let layoutFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            LayoutResolveInAppMessageEligibilityRemoteFlowEvaluator(layoutEvaluator: layoutEvaluator)
        )

        let deduplicateFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            FrequencyCapInAppMessageEligibilityFlowEvaluator(frequencyCapMatcher: InAppMessageFrequencyCapMatcher(storage: impressionStorage)),
            HiddenInAppMessageEligibilityFlowEvaluator(hiddenMatcher: InAppMessageHiddenMatcher(storage: hiddenStorage))
        )

        let eligibleFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            EligibleInAppMessageEligibilityFlowEvaluator()
        )

        self.triggerFlow = evaluationFlow + layoutFlow + deduplicateFlow + eligibleFlow
        self.deliverFlow = overrideFlow + deduplicateFlow + eligibleFlow
        self.deliverReEvaluationFlow = evaluationFlow + deduplicateFlow + eligibleFlow
    }

    func get(request: InAppMessageEligibilityRemoteEvaluateRequest) -> InAppMessageEligibilityRemoteEvaluationFlow {
        switch request.scope {
        case .trigger:
            return triggerFlow
        case .deliver:
            return request.result.evaluateContext.atDeliverTime ? deliverReEvaluationFlow : deliverFlow
        }
    }
}
