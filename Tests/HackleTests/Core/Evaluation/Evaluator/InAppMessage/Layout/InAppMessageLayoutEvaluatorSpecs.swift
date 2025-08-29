import Foundation
import Nimble
import Quick
@testable import Hackle

class InAppMessageLayoutEvaluatorSpecs: QuickSpec {
    override func spec() {

        var evaluator: MockEvaluator!
        var eventRecorder: MockEvaluationEventRecorder!
        var sut: InAppMessageLayoutEvaluator!

        beforeEach {
            evaluator = MockEvaluator()
            eventRecorder = MockEvaluationEventRecorder()
            let experimentEvaluator = InAppMessageExperimentEvaluator(
                evaluator: evaluator
            )
            let selector = InAppMessageLayoutSelector()
            sut = InAppMessageLayoutEvaluator(
                experimentEvaluator: experimentEvaluator,
                selector: selector,
                eventRecorder: eventRecorder
            )
        }

        it("supports") {
            expect(sut.support(request: InAppMessage.layoutRequest())) == true
            expect(sut.support(request: InAppMessage.eligibilityRequest())) == false
        }

        describe("experiment") {
            it("when cannot get experiment then throws error") {
                let messageContext = InAppMessage.messageContext(experimentContext: InAppMessage.ExperimentContext(key: 42))
                let inAppMessage = InAppMessage.create(messageContext: messageContext)
                let request = InAppMessage.layoutRequest(inAppMessage: inAppMessage)

                expect {
                    let _: InAppMessageLayoutEvaluation = try sut.evaluate(request: request, context: Evaluators.context())
                }
                    .to(throwError())
            }

            it("evaluate by variation") {
                // given
                let message = InAppMessage.message(variationKey: "B")
                let messageContext = InAppMessage.messageContext(
                    experimentContext: InAppMessage.ExperimentContext(key: 42),
                    messages: [message]
                )
                let inAppMessage = InAppMessage.create(messageContext: messageContext)

                let experiment = experiment(id: 5, key: 42)
                let workspace = WorkspaceEntity.create(experiments: [experiment])
                let request = InAppMessage.layoutRequest(workspace: workspace, inAppMessage: inAppMessage)
                let evaluation = experimentEvaluation(
                    reason: DecisionReason.TRAFFIC_ALLOCATED,
                    targetEvaluations: [],
                    experiment: experiment,
                    variationId: 320,
                    variationKey: "B"
                )
                evaluator.returns = evaluation
                let context = Evaluators.context()

                // when
                let actual: InAppMessageLayoutEvaluation = try sut.evaluate(request: request, context: context)

                // then
                expect(actual.message).to(be(message))
                expect(actual.reason) == "IN_APP_MESSAGE_TARGET"
                expect(actual.targetEvaluations[0]).to(be(evaluation))
                expect(actual.properties["experiment_id"]).to(be(5))
                expect(actual.properties["experiment_key"]).to(be(42))
                expect(actual.properties["variation_id"]).to(be(320))
                expect(actual.properties["variation_key"]).to(be("B"))
                expect(actual.properties["experiment_decision_reason"] as? String).to(equal("TRAFFIC_ALLOCATED"))
            }


            it("cannot evaluate when lang matches but variation key mismatches") {
                // given
                let message = InAppMessage.message(variationKey: "A", lang: "en")
                let messageContext = InAppMessage.messageContext(
                    defaultLang: "en",
                    experimentContext: InAppMessage.ExperimentContext(key: 42),
                    messages: [message]
                )
                let inAppMessage = InAppMessage.create(messageContext: messageContext)

                let experiment = experiment(id: 5, key: 42)
                let workspace = WorkspaceEntity.create(experiments: [experiment])
                let request = InAppMessage.layoutRequest(workspace: workspace, inAppMessage: inAppMessage)
                let evaluation = experimentEvaluation(
                    reason: DecisionReason.TRAFFIC_ALLOCATED,
                    targetEvaluations: [],
                    experiment: experiment,
                    variationId: 320,
                    variationKey: "B"
                )
                evaluator.returns = evaluation

                expect {
                    let _: InAppMessageLayoutEvaluation = try sut.evaluate(request: request, context: Evaluators.context())
                }
                    .to(throwError())
            }
        }

        describe("default") {

            it("evaluate") {
                // given
                let message = InAppMessage.message(lang: "ko")
                let inAppMessage = InAppMessage.create(
                    messageContext: InAppMessage.messageContext(
                        defaultLang: "ko",
                        messages: [message]
                    )
                )
                let request = InAppMessage.layoutRequest(inAppMessage: inAppMessage)

                // when
                let actual: InAppMessageLayoutEvaluation = try sut.evaluate(request: request, context: Evaluators.context())

                // then
                expect(actual.reason).to(equal("IN_APP_MESSAGE_TARGET"))
                expect(actual.message).to(beIdenticalTo(message))
            }

            it("not match") {
                let message = InAppMessage.message(lang: "en")
                let inAppMessage = InAppMessage.create(
                    messageContext: InAppMessage.messageContext(
                        defaultLang: "ko",
                        messages: [message]
                    )
                )
                let request = InAppMessage.layoutRequest(inAppMessage: inAppMessage)

                expect {
                    let _: InAppMessageLayoutEvaluation = try sut.evaluate(request: request, context: Evaluators.context())
                }
                    .to(throwError())
            }
        }

        it("record") {
            // given
            let request = InAppMessage.layoutRequest()
            let evaluation = InAppMessage.layoutEvaluation()

            // when
            sut.record(request: request, evaluation: evaluation)

            // then
            verify(exactly: 1) {
                eventRecorder.recordMock
            }
        }
    }
}
