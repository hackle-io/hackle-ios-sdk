import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityEvaluatorSpecs: QuickSpec {

    class FlowFactoryStub: InAppMessageEligibilityLocalEvaluationFlowFactory {
        let flow: InAppMessageEligibilityLocalEvaluationFlow
        init(flow: InAppMessageEligibilityLocalEvaluationFlow) {
            self.flow = flow
        }
        func get(request: InAppMessageEligibilityLocalEvaluateRequest) -> InAppMessageEligibilityLocalEvaluationFlow {
            flow
        }
    }

    static func layoutResponse(request: InAppMessageEligibilityLocalEvaluateRequest, layout: InAppMessageLayoutEvaluation) -> InAppMessageLayoutEvaluateResponse {
        InAppMessageLayoutEvaluateResponse(
            user: request.user,
            workspace: request.workspace,
            evaluation: layout,
            references: [],
            experiment: nil
        )
    }

    override class func spec() {

        it("supports") {
            let sut = InAppMessageEligibilityLocalEvaluator(
                evaluationFlowFactory: FlowFactoryStub(flow: .end()),
                eventRecorder: MockEvaluationEventRecorder()
            )
            expect(sut.supports(request: experimentRequest())) == false
            expect(sut.supports(request: remoteConfigRequest())) == false
            expect(sut.supports(request: InAppMessage.eligibilityRequest())) == true
        }

        describe("evaluate") {
            it("circular") {
                let sut = InAppMessageEligibilityLocalEvaluator(
                    evaluationFlowFactory: FlowFactoryStub(flow: .end()),
                    eventRecorder: MockEvaluationEventRecorder()
                )

                let request = InAppMessage.eligibilityRequest()
                let context = Evaluators.context()
                context.add(request)

                expect {
                    let _: InAppMessageEligibilityEvaluateResponse = try sut.evaluate(request: request, context: context)
                }
                    .to(throwError())
            }

            context("flow") {
                it("evaluation") {
                    let evaluation = InAppMessage.eligibilityEvaluation()
                    let flow: InAppMessageEligibilityLocalEvaluationFlow = InAppMessageEligibilityLocalEvaluationFlow.create(evaluation)
                    let sut = InAppMessageEligibilityLocalEvaluator(
                        evaluationFlowFactory: FlowFactoryStub(flow: flow),
                        eventRecorder: MockEvaluationEventRecorder()
                    )

                    let request = InAppMessage.eligibilityRequest()
                    let context = Evaluators.context()

                    let response: InAppMessageEligibilityEvaluateResponse = try sut.evaluate(request: request, context: context)

                    expect(response.eligibilityEvaluation.eligibilityResult.reason) == evaluation.eligibilityResult.reason
                    expect(response.eligibilityEvaluation.eligibilityResult.isEligible) == evaluation.eligibilityResult.isEligible
                }

                it("default") {
                    let sut = InAppMessageEligibilityLocalEvaluator(
                        evaluationFlowFactory: FlowFactoryStub(flow: .end()),
                        eventRecorder: MockEvaluationEventRecorder()
                    )

                    let request = InAppMessage.eligibilityRequest()
                    let context = Evaluators.context()

                    let response: InAppMessageEligibilityEvaluateResponse = try sut.evaluate(request: request, context: context)

                    expect(response.eligibilityEvaluation.eligibilityResult.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET
                }
            }
        }

        describe("record") {

            var eventRecorder: MockEvaluationEventRecorder!
            var sut: InAppMessageEligibilityLocalEvaluator!

            beforeEach {
                eventRecorder = MockEvaluationEventRecorder()
                sut = InAppMessageEligibilityLocalEvaluator(evaluationFlowFactory: FlowFactoryStub(flow: .end()), eventRecorder: eventRecorder)
            }

            func response(request: InAppMessageEligibilityLocalEvaluateRequest, isEligible: Bool, layout: InAppMessageLayoutEvaluateResponse?) -> InAppMessageEligibilityEvaluateResponse {
                InAppMessageEligibilityEvaluateResponse(
                    user: request.user,
                    workspace: request.workspace,
                    evaluation: InAppMessage.eligibilityEvaluation(isEligible: isEligible),
                    references: [],
                    layout: layout
                )
            }

            it("record eligibility evaluation") {
                let request = InAppMessage.eligibilityRequest()
                let resp = response(request: request, isEligible: true, layout: nil)

                sut.record(request: request, response: resp)

                expect(eventRecorder.recordCount) == 1
                expect(eventRecorder.records[0] as? InAppMessageEligibilityEvaluateResponse).to(beIdenticalTo(resp))
            }

            it("when eligible then do not record layout evaluation") {
                let request = InAppMessage.eligibilityRequest()
                let layout = layoutResponse(request: request, layout: InAppMessage.layoutEvaluation())
                let resp = response(request: request, isEligible: true, layout: layout)

                sut.record(request: request, response: resp)

                expect(eventRecorder.recordCount) == 1
                expect(eventRecorder.records[0] as? InAppMessageEligibilityEvaluateResponse).to(beIdenticalTo(resp))
            }

            it("when ineligible without layout then do not record layout") {
                let request = InAppMessage.eligibilityRequest()
                let resp = response(request: request, isEligible: false, layout: nil)

                sut.record(request: request, response: resp)

                expect(eventRecorder.recordCount) == 1
                expect(eventRecorder.records[0] as? InAppMessageEligibilityEvaluateResponse).to(beIdenticalTo(resp))
            }

            it("when ineligible with layout then record layout evaluation") {
                let request = InAppMessage.eligibilityRequest()
                let layout = layoutResponse(request: request, layout: InAppMessage.layoutEvaluation())
                let resp = response(request: request, isEligible: false, layout: layout)

                sut.record(request: request, response: resp)

                expect(eventRecorder.recordCount) == 2
                expect(eventRecorder.records[0] as? InAppMessageEligibilityEvaluateResponse).to(beIdenticalTo(resp))
                expect(eventRecorder.records[1] as? InAppMessageLayoutEvaluateResponse).to(beIdenticalTo(layout))
            }
        }
    }
}
