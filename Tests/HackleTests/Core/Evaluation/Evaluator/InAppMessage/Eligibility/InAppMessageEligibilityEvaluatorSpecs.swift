import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityEvaluatorSpecs: QuickSpec {
    override func spec() {

        it("supports") {
            let sut = InAppMessageEligibilityEvaluator(
                flow: InAppMessageEligibilityFlow.end(),
                eventRecorder: MockEvaluationEventRecorder()
            )
            expect(sut.support(request: experimentRequest())) == false
            expect(sut.support(request: remoteConfigRequest())) == false
            expect(sut.support(request: InAppMessage.eligibilityRequest())) == true
        }

        describe("evaluate") {
            it("circular") {
                let sut = InAppMessageEligibilityEvaluator(
                    flow: InAppMessageEligibilityFlow.end(),
                    eventRecorder: MockEvaluationEventRecorder()
                )

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
                    let eventRecorder = MockEvaluationEventRecorder()
                    let sut = InAppMessageEligibilityEvaluator(
                        flow: flow,
                        eventRecorder: eventRecorder
                    )

                    let request = InAppMessage.eligibilityRequest()
                    let context = Evaluators.context()

                    let actual: InAppMessageEligibilityEvaluation = try sut.evaluate(request: request, context: context)

                    expect(actual).to(beIdenticalTo(evaluation))
                }

                it("default") {
                    let flow: InAppMessageEligibilityFlow = InAppMessageEligibilityFlow.end()
                    let eventRecorder = MockEvaluationEventRecorder()
                    let sut = InAppMessageEligibilityEvaluator(
                        flow: flow,
                        eventRecorder: eventRecorder
                    )

                    let request = InAppMessage.eligibilityRequest()
                    let context = Evaluators.context()

                    let actual: InAppMessageEligibilityEvaluation = try sut.evaluate(request: request, context: context)

                    expect(actual.reason) == DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET
                }
            }
        }

        describe("record") {

            var eventRecorder: MockEvaluationEventRecorder!
            var sut: InAppMessageEligibilityEvaluator!

            beforeEach {
                eventRecorder = MockEvaluationEventRecorder()
                sut = InAppMessageEligibilityEvaluator(flow: .end(), eventRecorder: eventRecorder)
            }

            it("record eligibility evaluation") {
                // given
                let request = InAppMessage.eligibilityRequest()
                let evaluation = InAppMessage.eligibilityEvaluation()

                // when
                sut.record(request: request, evaluation: evaluation)

                // then
                verify(exactly: 1) {
                    eventRecorder.recordMock
                }
                expect(eventRecorder.recordMock.firstInvokation().arguments.1).to(beIdenticalTo(evaluation))
            }

            it("when eligible then do not record layout evaluation") {
                // given
                let request = InAppMessage.eligibilityRequest()
                let layoutEvaluation = InAppMessage.layoutEvaluation()
                let evaluation = InAppMessage.eligibilityEvaluation(
                    isEligible: true,
                    layoutEvaluation: layoutEvaluation
                )

                // when
                sut.record(request: request, evaluation: evaluation)

                // then
                verify(exactly: 1) {
                    eventRecorder.recordMock
                }
                expect(eventRecorder.recordMock.firstInvokation().arguments.1).to(beIdenticalTo(evaluation))
            }

            it("when ineligible without layout then do not record layout") {
                // given
                let request = InAppMessage.eligibilityRequest()
                let evaluation = InAppMessage.eligibilityEvaluation(
                    isEligible: false,
                    layoutEvaluation: nil
                )

                // when
                sut.record(request: request, evaluation: evaluation)

                // then
                verify(exactly: 1) {
                    eventRecorder.recordMock
                }
                expect(eventRecorder.recordMock.firstInvokation().arguments.1).to(beIdenticalTo(evaluation))
            }

            it("when ineligible with layout then record layout evaluation") {
                // given
                let request = InAppMessage.eligibilityRequest()
                let layoutEvaluation = InAppMessage.layoutEvaluation()
                let evaluation = InAppMessage.eligibilityEvaluation(
                    isEligible: false,
                    layoutEvaluation: layoutEvaluation
                )

                // when
                sut.record(request: request, evaluation: evaluation)

                // then
                verify(exactly: 2) {
                    eventRecorder.recordMock
                }
                expect(eventRecorder.recordMock.invokations()[0].arguments.1).to(beIdenticalTo(evaluation))
                expect(eventRecorder.recordMock.invokations()[1].arguments.1).to(beIdenticalTo(layoutEvaluation))
            }
        }
    }
}
