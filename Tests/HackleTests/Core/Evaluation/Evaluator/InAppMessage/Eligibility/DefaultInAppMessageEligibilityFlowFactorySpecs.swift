import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultInAppMessageEligibilityFlowFactorySpecs: QuickSpec {
    override class func spec() {

        var sut: DefaultInAppMessageEligibilityLocalEvaluationFlowFactory!

        beforeEach {
            let targetMatcher = DefaultTargetMatcher(
                conditionMatcherFactory: DefaultConditionMatcherFactory(evaluator: DelegatingEvaluator(evaluatorFactory: EvaluatorFactory()), clock: SystemClock.shared)
            )
            let layoutEvaluator = InAppMessageLayoutLocalEvaluator(
                experimentEvaluator: InAppMessageLayoutExperimentEvaluator(evaluator: DelegatingEvaluator(evaluatorFactory: EvaluatorFactory())),
                selector: InAppMessageLayoutSelector(),
                eventRecorder: MockEvaluationEventRecorder()
            )
            sut = DefaultInAppMessageEligibilityLocalEvaluationFlowFactory(
                targetMatcher: targetMatcher,
                impressionStorage: DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()),
                hiddenStorage: DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()),
                layoutEvaluator: layoutEvaluator
            )
        }

        func request(scope: InAppMessageEvaluateScope, atDeliverTime: Bool = false) -> InAppMessageEligibilityLocalEvaluateRequest {
            let inAppMessage = InAppMessage.create(evaluateContext: InAppMessage.evaluateContext(atDeliverTime: atDeliverTime))
            return InAppMessage.eligibilityRequest(inAppMessage: inAppMessage, scope: scope)
        }

        it("trigger flow") {
            sut.get(request: request(scope: .trigger))
                .isDecisionWith(PlatformInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(OverrideInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(DraftInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(PauseInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(PeriodInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(TimetableInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(TargetInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(LayoutResolveInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()
        }

        it("deliver flow (not re-evaluate)") {
            sut.get(request: request(scope: .deliver, atDeliverTime: false))
                .isDecisionWith(OverrideInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()
        }

        it("deliver flow (re-evaluate)") {
            sut.get(request: request(scope: .deliver, atDeliverTime: true))
                .isDecisionWith(PlatformInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(OverrideInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(DraftInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(PauseInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(PeriodInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(TimetableInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(TargetInAppMessageEligibilityLocalFlowEvaluator.self)!
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()
        }
    }
}
