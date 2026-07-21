import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityRemoteEvaluationFlowFactorySpecs: QuickSpec {
    override class func spec() {

        var sut: DefaultInAppMessageEligibilityRemoteEvaluationFlowFactory!

        beforeEach {
            sut = DefaultInAppMessageEligibilityRemoteEvaluationFlowFactory(
                impressionStorage: DefaultInAppMessageImpressionStorage(keyValueRepository: MemoryKeyValueRepository()),
                hiddenStorage: DefaultInAppMessageHiddenStorage(keyValueRepository: MemoryKeyValueRepository()),
                layoutEvaluator: InAppMessageLayoutRemoteEvaluator(eventRecorder: MockEvaluationEventRecorder())
            )
        }

        it("trigger flow") {
            sut.get(request: iamRemoteRequest(scope: .trigger))
                .isDecisionWith(PlatformInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(OverrideInAppMessageEligibilityRemoteFlowEvaluator.self)!
                .isDecisionWith(IneligibleInAppMessageEligibilityRemoteFlowEvaluator.self)!
                .isDecisionWith(PeriodInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(TimetableInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(LayoutResolveInAppMessageEligibilityRemoteFlowEvaluator.self)!
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()
        }

        it("deliver flow (not re-evaluate)") {
            sut.get(request: iamRemoteRequest(scope: .deliver, atDeliverTime: false))
                .isDecisionWith(OverrideInAppMessageEligibilityRemoteFlowEvaluator.self)!
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()
        }

        it("deliver flow (re-evaluate)") {
            sut.get(request: iamRemoteRequest(scope: .deliver, atDeliverTime: true))
                .isDecisionWith(PlatformInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(OverrideInAppMessageEligibilityRemoteFlowEvaluator.self)!
                .isDecisionWith(IneligibleInAppMessageEligibilityRemoteFlowEvaluator.self)!
                .isDecisionWith(PeriodInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(TimetableInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(FrequencyCapInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(HiddenInAppMessageEligibilityFlowEvaluator.self)!
                .isDecisionWith(EligibleInAppMessageEligibilityFlowEvaluator.self)!
                .isEnd()
        }

        it("trigger scope: platform is evaluated first (unsupported platform -> UNSUPPORTED_PLATFORM)") {
            let request = iamRemoteRequest(scope: .trigger, platformType: .android)

            let evaluation = try sut.get(request: request).evaluate(request: request, context: Evaluators.context())

            expect(evaluation?.eligibilityResult.isEligible).to(beFalse())
            expect(evaluation?.eligibilityResult.reason).to(equal(DecisionReason.UNSUPPORTED_PLATFORM))
        }

        it("deliver scope without re-evaluation: override is evaluated first (server OVERRIDDEN -> eligible)") {
            let request = iamRemoteRequest(scope: .deliver, atDeliverTime: false, isEligible: false, reason: DecisionReason.OVERRIDDEN)

            let evaluation = try sut.get(request: request).evaluate(request: request, context: Evaluators.context())

            expect(evaluation?.eligibilityResult.isEligible).to(beTrue())
            expect(evaluation?.eligibilityResult.reason).to(equal(DecisionReason.OVERRIDDEN))
        }

        it("deliver scope with re-evaluation: ineligible evaluator is reached (server isEligible=false -> ineligible)") {
            let request = iamRemoteRequest(scope: .deliver, atDeliverTime: true, isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)

            let evaluation = try sut.get(request: request).evaluate(request: request, context: Evaluators.context())

            expect(evaluation?.eligibilityResult.isEligible).to(beFalse())
            expect(evaluation?.eligibilityResult.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET))
        }
    }
}
