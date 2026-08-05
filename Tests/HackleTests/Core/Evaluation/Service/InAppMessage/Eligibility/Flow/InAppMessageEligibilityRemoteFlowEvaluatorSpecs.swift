import Foundation
import Quick
import Nimble
@testable import Hackle

func iamRemoteRequest(
    scope: InAppMessageEvaluateScope = .trigger,
    atDeliverTime: Bool = false,
    isEligible: Bool = true,
    reason: String = DecisionReason.IN_APP_MESSAGE_TARGET,
    platformType: PlatformType = .ios,
    workspace: WorkspaceEvaluation = MockWorkspaceEvaluation(),
    user: HackleUser = HackleUser.builder().identifier(.id, "user").build(),
    timestamp: Date = Date()
) -> InAppMessageEligibilityRemoteEvaluateRequest {
    let result = inAppMessageEligibilityRemoteResult(
        isEligible: isEligible,
        reason: reason,
        evaluateContext: InAppMessageEntity.evaluateContext(atDeliverTime: atDeliverTime)
    )
    return InAppMessageEligibilityRemoteEvaluateRequest.of(
        workspace: workspace,
        entity: result,
        user: user,
        scope: scope,
        platformType: platformType,
        timestamp: timestamp
    )
}

class InAppMessageEligibilityRemoteFlowEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var context: EvaluatorContext!
        var nextFlow: InAppMessageEligibilityRemoteEvaluationFlow!

        beforeEach {
            context = Evaluators.context()
            nextFlow = InAppMessageEligibilityRemoteEvaluationFlow.of(EligibleInAppMessageEligibilityFlowEvaluator())
        }

        describe("OverrideInAppMessageEligibilityRemoteFlowEvaluator") {

            let sut = OverrideInAppMessageEligibilityRemoteFlowEvaluator()

            it("when server reason is OVERRIDDEN then eligible OVERRIDDEN") {
                let request = iamRemoteRequest(isEligible: false, reason: DecisionReason.OVERRIDDEN)

                let evaluation = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                expect(evaluation?.eligibilityResult.isEligible).to(beTrue())
                expect(evaluation?.eligibilityResult.reason).to(equal(DecisionReason.OVERRIDDEN))
            }

            it("when server reason is not OVERRIDDEN then pass through to nextFlow") {
                let request = iamRemoteRequest(reason: DecisionReason.IN_APP_MESSAGE_TARGET)

                let evaluation = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                expect(evaluation?.eligibilityResult.isEligible).to(beTrue())
                expect(evaluation?.eligibilityResult.reason).to(equal(DecisionReason.IN_APP_MESSAGE_TARGET))
            }
        }

        describe("IneligibleInAppMessageEligibilityRemoteFlowEvaluator") {

            it("Ineligible evaluator returns server reason when not eligible") {
                let request = iamRemoteRequest(isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
                let evaluation = try IneligibleInAppMessageEligibilityRemoteFlowEvaluator().evaluate(
                    request: request,
                    context: Evaluators.context(),
                    nextFlow: InAppMessageEligibilityRemoteEvaluationFlow.of(EligibleInAppMessageEligibilityFlowEvaluator())
                )
                expect(evaluation?.eligibilityResult.isEligible).to(beFalse())
                expect(evaluation?.eligibilityResult.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET))
            }

            it("when server isEligible is true then pass through to nextFlow") {
                let sut = IneligibleInAppMessageEligibilityRemoteFlowEvaluator()
                let request = iamRemoteRequest(isEligible: true, reason: DecisionReason.IN_APP_MESSAGE_TARGET)

                let evaluation = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                expect(evaluation?.eligibilityResult.isEligible).to(beTrue())
                expect(evaluation?.eligibilityResult.reason).to(equal(DecisionReason.IN_APP_MESSAGE_TARGET))
            }
        }

        describe("LayoutResolveInAppMessageEligibilityRemoteFlowEvaluator") {

            var sut: LayoutResolveInAppMessageEligibilityRemoteFlowEvaluator!

            beforeEach {
                sut = LayoutResolveInAppMessageEligibilityRemoteFlowEvaluator(
                    layoutEvaluator: InAppMessageLayoutRemoteEvaluator(eventRecorder: MockEvaluationEventRecorder())
                )
            }

            it("resolves layout via the layout evaluator, stores it in the context, then passes through to nextFlow") {
                let request = iamRemoteRequest(reason: DecisionReason.IN_APP_MESSAGE_TARGET)

                let evaluation = try sut.evaluate(request: request, context: context, nextFlow: nextFlow)

                expect(context.get(InAppMessageLayoutEvaluateResponse.self)).toNot(beNil())
                expect(evaluation?.eligibilityResult.isEligible).to(beTrue())
                expect(evaluation?.eligibilityResult.reason).to(equal(DecisionReason.IN_APP_MESSAGE_TARGET))
            }
        }
    }
}
