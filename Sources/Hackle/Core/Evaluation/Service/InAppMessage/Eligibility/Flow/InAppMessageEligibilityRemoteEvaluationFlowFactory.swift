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
        let platformFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            PlatformInAppMessageEligibilityFlowEvaluator()
        )

        let overrideFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            OverrideInAppMessageEligibilityRemoteFlowEvaluator()
        )

        let ineligibleFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            IneligibleInAppMessageEligibilityRemoteFlowEvaluator()
        )

        let timeFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            PeriodInAppMessageEligibilityFlowEvaluator(),
            TimetableInAppMessageEligibilityFlowEvaluator()
        )

        let layoutFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            LayoutResolveInAppMessageEligibilityRemoteFlowEvaluator(layoutEvaluator: layoutEvaluator)
        )

        let dedupFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            FrequencyCapInAppMessageEligibilityFlowEvaluator(frequencyCapMatcher: InAppMessageFrequencyCapMatcher(storage: impressionStorage)),
            HiddenInAppMessageEligibilityFlowEvaluator(hiddenMatcher: InAppMessageHiddenMatcher(storage: hiddenStorage))
        )

        let eligibleFlow: InAppMessageEligibilityRemoteEvaluationFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(
            EligibleInAppMessageEligibilityFlowEvaluator()
        )

        self.triggerFlow = platformFlow + overrideFlow + ineligibleFlow + timeFlow + layoutFlow + dedupFlow + eligibleFlow
        self.deliverFlow = overrideFlow + dedupFlow + eligibleFlow
        self.deliverReEvaluationFlow = platformFlow + overrideFlow + ineligibleFlow + timeFlow + dedupFlow + eligibleFlow
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
