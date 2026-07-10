import Foundation
import Quick
import Nimble
@testable import Hackle

class InAppMessageLayoutRemoteEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var eventProcessor: MockUserEventProcessor!
        var sut: InAppMessageLayoutRemoteEvaluator!

        beforeEach {
            eventProcessor = MockUserEventProcessor()
            sut = InAppMessageLayoutRemoteEvaluator(
                eventRecorder: EvaluationEventRecorder(
                    eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
                    eventProcessor: eventProcessor
                )
            )
        }

        it("supports only InAppMessageLayoutRemoteEvaluateRequest") {
            let request = InAppMessageLayoutRemoteEvaluateRequest.of(
                workspace: MockWorkspaceEvaluation(),
                entity: inAppMessageLayoutRemoteResult(),
                user: HackleUser.builder().build(),
                scope: .trigger
            )
            expect(sut.supports(request: request)).to(beTrue())
        }

        it("remoteEvaluate passes through the server-evaluated message and reason") {
            let result = inAppMessageLayoutRemoteResult(reason: DecisionReason.IN_APP_MESSAGE_TARGET)
            let request = InAppMessageLayoutRemoteEvaluateRequest.of(
                workspace: MockWorkspaceEvaluation(),
                entity: result,
                user: HackleUser.builder().build(),
                scope: .trigger
            )

            let response: InAppMessageLayoutEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())

            expect(response.layoutEvaluation.entity.entityKey).to(equal(result.entityKey))
            expect(response.layoutEvaluation.layoutResult.reason).to(equal(DecisionReason.IN_APP_MESSAGE_TARGET))
        }
    }
}
