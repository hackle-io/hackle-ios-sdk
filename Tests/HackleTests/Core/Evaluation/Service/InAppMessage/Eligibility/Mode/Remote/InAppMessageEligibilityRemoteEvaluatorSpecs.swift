import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageEligibilityRemoteEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var flowFactory: MockInAppMessageEligibilityRemoteEvaluationFlowFactory!
        var eventProcessor: MockUserEventProcessor!
        var sut: InAppMessageEligibilityRemoteEvaluator!

        beforeEach {
            flowFactory = MockInAppMessageEligibilityRemoteEvaluationFlowFactory()
            eventProcessor = MockUserEventProcessor()
            sut = InAppMessageEligibilityRemoteEvaluator(
                evaluationFlowFactory: flowFactory,
                eventRecorder: EvaluationEventRecorder(
                    eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
                    eventProcessor: eventProcessor
                )
            )
        }

        func request(isEligible: Bool = true, reason: String = DecisionReason.IN_APP_MESSAGE_TARGET) -> InAppMessageEligibilityRemoteEvaluateRequest {
            InAppMessageEligibilityRemoteEvaluateRequest.of(
                workspace: MockWorkspaceEvaluation(),
                entity: inAppMessageEligibilityRemoteResult(isEligible: isEligible, reason: reason),
                user: HackleUser.builder().build(),
                scope: .trigger,
                platformType: .ios,
                timestamp: Date()
            )
        }

        describe("remoteEvaluate") {

            it("uses the flow evaluation result when flow returns one") {
                flowFactory.flow = InAppMessageEligibilityRemoteEvaluationFlow.of(
                    IneligibleInAppMessageEligibilityRemoteFlowEvaluator()
                )
                let req = request(isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)

                let response: InAppMessageEligibilityEvaluateResponse = try sut.evaluate(request: req, context: Evaluators.context())

                expect(response.eligibilityEvaluation.eligibilityResult.isEligible).to(beFalse())
                expect(response.eligibilityEvaluation.eligibilityResult.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET))
            }

            it("falls back to NOT_IN_IN_APP_MESSAGE_TARGET when flow returns nil") {
                flowFactory.flow = .end()

                let response: InAppMessageEligibilityEvaluateResponse = try sut.evaluate(request: request(), context: Evaluators.context())

                expect(response.eligibilityEvaluation.eligibilityResult.isEligible).to(beFalse())
                expect(response.eligibilityEvaluation.eligibilityResult.reason).to(equal(DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET))
            }

            it("stores the resolved layout response on the response when the flow resolves one") {
                // LayoutResolve가 context에 layout response를 set한 뒤 Ineligible로 끝나는 flow (P8 시나리오)
                let layoutEvaluator = InAppMessageLayoutRemoteEvaluator(
                    eventRecorder: EvaluationEventRecorder(
                        eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
                        eventProcessor: eventProcessor
                    )
                )
                flowFactory.flow = InAppMessageEligibilityRemoteEvaluationFlow.of(
                    LayoutResolveInAppMessageEligibilityRemoteFlowEvaluator(layoutEvaluator: layoutEvaluator),
                    IneligibleInAppMessageEligibilityRemoteFlowEvaluator()
                )
                let req = request(isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)

                let response: InAppMessageEligibilityEvaluateResponse = try sut.evaluate(request: req, context: Evaluators.context())

                expect(response.eligibilityEvaluation.eligibilityResult.isEligible).to(beFalse())
                expect(response.layout).toNot(beNil())
            }
        }

        describe("record") {

            // EvaluationEventFactory는 InAppMessage 계열 Evaluation(eligibility/layout)에 대해 이벤트를 생성하지 않으므로(0건),
            // eventProcessor 호출 수로는 layout 기록 여부를 구분할 수 없다.
            // LOCAL evaluator(InAppMessageEligibilityEvaluatorSpecs)의 record 스펙과 동일하게
            // MockEvaluationEventRecorder로 record(response:) 호출 자체를 검증한다.
            var eventRecorder: MockEvaluationEventRecorder!
            var recordSut: InAppMessageEligibilityRemoteEvaluator!

            beforeEach {
                eventRecorder = MockEvaluationEventRecorder()
                recordSut = InAppMessageEligibilityRemoteEvaluator(
                    evaluationFlowFactory: flowFactory,
                    eventRecorder: eventRecorder
                )
            }

            func response(isEligible: Bool, layout: InAppMessageLayoutEvaluateResponse?) -> InAppMessageEligibilityEvaluateResponse {
                InAppMessageEligibilityEvaluateResponse(
                    user: HackleUser.builder().build(),
                    workspace: MockWorkspaceEvaluation(),
                    evaluation: InAppMessageEntity.eligibilityEvaluation(isEligible: isEligible),
                    references: [],
                    layout: layout
                )
            }

            it("records eligibility evaluation") {
                let req = request()
                let resp = response(isEligible: true, layout: nil)

                recordSut.record(request: req, response: resp)

                expect(eventRecorder.recordCount) == 1
                expect(eventRecorder.records[0] as? InAppMessageEligibilityEvaluateResponse).to(beIdenticalTo(resp))
            }

            it("does not record layout when eligible") {
                let req = request()
                let layout = InAppMessageEntity.layoutEvaluateResponse()
                let resp = response(isEligible: true, layout: layout)

                recordSut.record(request: req, response: resp)

                expect(eventRecorder.recordCount) == 1
            }

            it("does not record layout when ineligible without a resolved layout") {
                let req = request(isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
                let resp = response(isEligible: false, layout: nil)

                recordSut.record(request: req, response: resp)

                expect(eventRecorder.recordCount) == 1
            }

            it("records layout response as well when ineligible with a resolved layout") {
                let req = request(isEligible: false, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
                let layout = InAppMessageEntity.layoutEvaluateResponse()
                let resp = response(isEligible: false, layout: layout)

                recordSut.record(request: req, response: resp)

                expect(eventRecorder.recordCount) == 2
                expect(eventRecorder.records[0] as? InAppMessageEligibilityEvaluateResponse).to(beIdenticalTo(resp))
                expect(eventRecorder.records[1] as? InAppMessageLayoutEvaluateResponse).to(beIdenticalTo(layout))
            }
        }
    }

    class MockInAppMessageEligibilityRemoteEvaluationFlowFactory: InAppMessageEligibilityRemoteEvaluationFlowFactory {
        var flow: InAppMessageEligibilityRemoteEvaluationFlow = .end()
        func get(request: InAppMessageEligibilityRemoteEvaluateRequest) -> InAppMessageEligibilityRemoteEvaluationFlow {
            flow
        }
    }
}
