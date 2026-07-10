import Foundation
import Quick
import Nimble
@testable import Hackle

class RemoteConfigRemoteEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var eventProcessor: MockUserEventProcessor!
        var sut: RemoteConfigRemoteEvaluator!

        beforeEach {
            eventProcessor = MockUserEventProcessor()
            sut = RemoteConfigRemoteEvaluator(
                eventRecorder: EvaluationEventRecorder(
                    eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
                    eventProcessor: eventProcessor
                )
            )
        }

        func request(result: RemoteConfigParameterRemoteEvaluateResult) -> RemoteConfigRemoteEvaluateRequest {
            RemoteConfigRemoteEvaluateRequest.of(
                workspace: MockWorkspaceEvaluation(),
                parameter: result,
                user: HackleUser.builder().build(),
                requiredType: .string
            )
        }

        it("supports only RemoteConfigRemoteEvaluateRequest") {
            expect(sut.supports(request: request(result: remoteConfigRemoteResult()))).to(beTrue())
        }

        it("remoteEvaluate passes through the server-evaluated value and reason") {
            let result = remoteConfigRemoteResult(reason: DecisionReason.TARGET_RULE_MATCH)

            let response: RemoteConfigEvaluateResponse = try sut.evaluate(request: request(result: result), context: Evaluators.context())

            expect(response.remoteConfigEvaluation.parameter.id).to(equal(result.id))
            expect(response.remoteConfigEvaluation.remoteConfigResult.value?.id).to(equal(7))
            expect(response.remoteConfigEvaluation.remoteConfigResult.reason).to(equal(DecisionReason.TARGET_RULE_MATCH))
        }

        it("record delegates to eventRecorder") {
            let req = request(result: remoteConfigRemoteResult())
            let response: RemoteConfigEvaluateResponse = try sut.evaluate(request: req, context: Evaluators.context())

            sut.record(request: req, response: response)

            verify(exactly: 1) {
                eventProcessor.processMock
            }
        }
    }
}
