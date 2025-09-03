import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageEligibilityFlowFactorySpecs: QuickSpec {
    override func spec() {

        var evaluationContext: EvaluationContext!
        var sut: DefaultInAppMessageEligibilityFlowFactory!

        beforeEach {
            evaluationContext = EvaluationContext()
            evaluationContext.register(DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()))
            evaluationContext.register(DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()))
            evaluationContext.initialize(
                evaluator: MockEvaluator(),
                manualOverrideStorage: DelegatingManualOverrideStorage(storages: []),
                clock: SystemClock.shared
            )
            sut = DefaultInAppMessageEligibilityFlowFactory(context: evaluationContext, layoutEvaluator: MockEvaluator())
        }

        it("flow") {
            sut.triggerFlow()
                .isDecisionWith(PlatformInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(OverrideInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(DraftInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(PausedInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(PeriodInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(TargetInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(LayoutResolveInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()

            sut.deliverFlow(reEvaluate: false)
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()

            sut.deliverFlow(reEvaluate: true)
                .isDecisionWith(PlatformInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(OverrideInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(DraftInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(PausedInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(PeriodInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(TargetInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()
        }
    }
}
