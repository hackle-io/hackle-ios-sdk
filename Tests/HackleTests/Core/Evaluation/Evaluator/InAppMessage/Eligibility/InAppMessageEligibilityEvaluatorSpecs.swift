import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityEvaluatorSpecs: QuickSpec {
    override func spec() {

        var evaluationFlowFactory: MockEvaluationFlowFactory!
        var sut: InAppMessageEligibilityEvaluator!

        beforeEach {
            evaluationFlowFactory = MockEvaluationFlowFactory()
            sut = InAppMessageEligibilityEvaluator(evaluationFlowFactory: evaluationFlowFactory)
        }

        it("supports") {
            expect(sut.support(request: experimentRequest())) == false
            expect(sut.support(request: remoteConfigRequest())) == false
            expect(sut.support(request: InAppMessage.eligibilityRequest())) == true
        }

        describe("evaluate") {
            it("circular") {
                let request = InAppMessage.eligibilityRequest()
                let context = Evaluators.context()
                context.add(request)

                expect {
                    let _: InAppMessageEligibilityEvaluation = try sut.evaluate(request: request, context: context)
                }
                    .to(throwError())
            }

            context("flow") {
                it("evaluation") {
                    let evaluation = InAppMessage.eligibilityEvaluation()

                    let flow: InAppMessageEligibilityFlow = InAppMessageEligibilityFlow.create(evaluation)
                    evaluationFlowFactory.inAppMessageFlow = flow

                    let request = InAppMessage.eligibilityRequest()
                    let context = Evaluators.context()

                    let actual: InAppMessageEligibilityEvaluation = try sut.evaluate(request: request, context: context)

                    expect(actual).to(beIdenticalTo(evaluation))
                }

                it("default") {
                    let request = InAppMessage.eligibilityRequest()
                    let context = Evaluators.context()

                    let actual: InAppMessageEligibilityEvaluation = try sut.evaluate(request: request, context: context)

                    expect(actual.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET
                }
            }
        }
    }
}
