import Foundation
import Nimble
import Quick
@testable import Hackle

class InAppMessageLayoutEvaluatorSpecs: QuickSpec {

    /// Stub experiment evaluator returning a preset ExperimentEvaluation.
    final class StubExperimentEvaluator: ExperimentEvaluator {
        let eventRecorder: EvaluationEventRecorder
        var evaluation: ExperimentEvaluation?

        init() {
            eventRecorder = MockEvaluationEventRecorder()
        }

        func evaluateInternal(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> ExperimentEvaluateResponse {
            let evaluation = evaluation ?? ExperimentEvaluation(
                entity: request.experiment,
                result: ExperimentEvaluateResult.of(reason: DecisionReason.TRAFFIC_ALLOCATED, variation: request.experiment.variations.first!, config: nil)
            )
            return ExperimentEvaluateResponse(user: request.user, workspace: request.workspace, evaluation: evaluation, references: context.references)
        }
    }

    override class func spec() {

        var experimentEvaluatorStub: StubExperimentEvaluator!
        var delegatingEvaluator: DelegatingEvaluator!
        var eventRecorder: MockEvaluationEventRecorder!
        var sut: InAppMessageLayoutLocalEvaluator!

        beforeEach {
            experimentEvaluatorStub = StubExperimentEvaluator()
            let evaluatorFactory = EvaluatorFactory()
            evaluatorFactory.add(experimentEvaluatorStub)
            delegatingEvaluator = DelegatingEvaluator(evaluatorFactory: evaluatorFactory)

            eventRecorder = MockEvaluationEventRecorder()
            sut = InAppMessageLayoutLocalEvaluator(
                experimentEvaluator: InAppMessageLayoutExperimentEvaluator(evaluator: delegatingEvaluator),
                selector: InAppMessageLayoutSelector(),
                eventRecorder: eventRecorder
            )
        }

        it("supports") {
            expect(sut.supports(request: InAppMessage.layoutRequest())) == true
            expect(sut.supports(request: InAppMessage.eligibilityRequest())) == false
        }

        describe("experiment") {
            it("when cannot get experiment then throws error") {
                let messageContext = InAppMessage.messageContext(experimentContext: InAppMessage.ExperimentContext(key: 42))
                let inAppMessage = InAppMessage.create(messageContext: messageContext)
                let request = InAppMessage.layoutRequest(inAppMessage: inAppMessage)

                expect {
                    let _: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
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
                expect(response.experiment?.experimentResult.variationKey) == "B"
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
                let message = InAppMessage.message(lang: "ko")
                let inAppMessage = InAppMessage.create(
                    messageContext: InAppMessage.messageContext(
                        defaultLang: "ko",
                        messages: [message]
                    )
                )
                let request = InAppMessage.layoutRequest(inAppMessage: inAppMessage)

                // when
                let response: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())

                // then
                expect(response.layoutEvaluation.layoutResult.reason) == DecisionReason.IN_APP_MESSAGE_TARGET
                expect(response.layoutEvaluation.layoutResult.message).to(beIdenticalTo(message))
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
                    let _: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())
                }
                    .to(throwError())
            }
        }

        it("record") {
            // given
            let request = InAppMessage.layoutRequest()
            let response = InAppMessageLayoutEvaluateResponse(
                user: request.user,
                workspace: request.workspace,
                evaluation: InAppMessage.layoutEvaluation(),
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
