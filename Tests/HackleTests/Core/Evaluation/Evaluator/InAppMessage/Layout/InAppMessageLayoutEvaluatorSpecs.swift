import Foundation
import Nimble
import Quick
@testable import Hackle

class InAppMessageLayoutEvaluatorSpecs: QuickSpec {

    override class func spec() {

        var experimentEvaluatorStub: StubExperimentEvaluator!
        var eventRecorder: MockEvaluationEventRecorder!
        var sut: InAppMessageLayoutLocalEvaluator!

        beforeEach {
            experimentEvaluatorStub = StubExperimentEvaluator(includeContextReferences: true)
            let evaluatorFactory = EvaluatorFactory()
            evaluatorFactory.add(experimentEvaluatorStub)

            eventRecorder = MockEvaluationEventRecorder()
            sut = InAppMessageLayoutLocalEvaluator(
                experimentEvaluator: ExperimentReferenceLocalEvaluator(evaluatorFactory: evaluatorFactory),
                selector: InAppMessageLayoutSelector(),
                eventRecorder: eventRecorder
            )
        }

        it("supports") {
            expect(sut.supports(request: InAppMessageEntity.layoutRequest())) == true
            expect(sut.supports(request: InAppMessageEntity.eligibilityRequest())) == false
        }

        describe("experiment") {
            it("when cannot get experiment then throws") {
                let messageContext = InAppMessageEntity.messageContext(experimentContext: InAppMessage.ExperimentContext(key: 42))
                let inAppMessage = InAppMessageEntity.create(messageContext: messageContext)
                let request = InAppMessageEntity.layoutRequest(inAppMessage: inAppMessage)

                expect {
                    let _: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
                }
                    .to(throwError())
            }

            it("evaluate by variation") {
                // given
                let message = InAppMessageEntity.message(variationKey: "B")
                let messageContext = InAppMessageEntity.messageContext(
                    experimentContext: InAppMessage.ExperimentContext(key: 42),
                    messages: [message]
                )
                let inAppMessage = InAppMessageEntity.create(messageContext: messageContext)

                let experiment = experiment(id: 5, key: 42)
                let workspace = DefaultWorkspaceConfig.create(experiments: [experiment])
                let request = InAppMessageEntity.layoutRequest(workspace: workspace, inAppMessage: inAppMessage)
                experimentEvaluatorStub.evaluation = experimentEvaluation(
                    reason: DecisionReason.TRAFFIC_ALLOCATED,
                    experiment: experiment,
                    variationId: 320,
                    variationKey: "B"
                )
                let context = Evaluators.context()

                // when
                let response: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: context)

                // then
                expect(response.layoutEvaluation.layoutResult.message).to(be(message))
                expect(response.layoutEvaluation.layoutResult.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
                expect(response.experiment?.experimentResult.variation.key) == "B"
            }

            it("cannot evaluate when lang matches but variation key mismatches") {
                // given
                let message = InAppMessageEntity.message(variationKey: "A", lang: "en")
                let messageContext = InAppMessageEntity.messageContext(
                    defaultLang: "en",
                    experimentContext: InAppMessage.ExperimentContext(key: 42),
                    messages: [message]
                )
                let inAppMessage = InAppMessageEntity.create(messageContext: messageContext)

                let experiment = experiment(id: 5, key: 42)
                let workspace = DefaultWorkspaceConfig.create(experiments: [experiment])
                let request = InAppMessageEntity.layoutRequest(workspace: workspace, inAppMessage: inAppMessage)
                experimentEvaluatorStub.evaluation = experimentEvaluation(
                    reason: DecisionReason.TRAFFIC_ALLOCATED,
                    experiment: experiment,
                    variationId: 320,
                    variationKey: "B"
                )

                expect {
                    let _: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
                }
                    .to(throwError())
            }
        }

        describe("default") {

            it("evaluate") {
                // given
                let message = InAppMessageEntity.message(lang: "ko")
                let inAppMessage = InAppMessageEntity.create(
                    messageContext: InAppMessageEntity.messageContext(
                        defaultLang: "ko",
                        messages: [message]
                    )
                )
                let request = InAppMessageEntity.layoutRequest(inAppMessage: inAppMessage)

                // when
                let response: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())

                // then
                expect(response.layoutEvaluation.layoutResult.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
                expect(response.layoutEvaluation.layoutResult.message).to(beIdenticalTo(message))
            }

            it("not match") {
                let message = InAppMessageEntity.message(lang: "en")
                let inAppMessage = InAppMessageEntity.create(
                    messageContext: InAppMessageEntity.messageContext(
                        defaultLang: "ko",
                        messages: [message]
                    )
                )
                let request = InAppMessageEntity.layoutRequest(inAppMessage: inAppMessage)

                expect {
                    let _: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
                }
                    .to(throwError())
            }
        }

        it("record") {
            // given
            let request = InAppMessageEntity.layoutRequest()
            let response = InAppMessageLayoutEvaluateResponse(
                user: request.user,
                workspace: request.workspace,
                evaluation: InAppMessageEntity.layoutEvaluation(),
                references: [],
                experiment: nil
            )

            // when
            sut.record(request: request, response: response)

            // then
            expect(eventRecorder.recordCount) == 1
        }
    }
}
