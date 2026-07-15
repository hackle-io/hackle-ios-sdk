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

        func request(result: RemoteConfigParameterRemoteEvaluateResult, requiredType: HackleValueType = .string) -> RemoteConfigRemoteEvaluateRequest {
            RemoteConfigRemoteEvaluateRequest.of(
                workspace: MockWorkspaceEvaluation(),
                parameter: result,
                user: HackleUser.builder().build(),
                requiredType: requiredType
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

        func makeEvaluator() -> RemoteConfigRemoteEvaluator {
            RemoteConfigRemoteEvaluator(
                eventRecorder: EvaluationEventRecorder(
                    eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
                    eventProcessor: MockUserEventProcessor()
                )
            )
        }

        it("requiredType과 값 타입이 일치하지 않으면 TYPE_MISMATCH로 반환한다 (value 유지)") {
            let localSut = makeEvaluator()
            let result = remoteConfigRemoteResult(value: RemoteConfigParameter.Value(id: 7, rawValue: HackleValue.string("v")), reason: DecisionReason.TARGET_RULE_MATCH)

            let response: RemoteConfigEvaluateResponse = try localSut.evaluate(request: request(result: result, requiredType: .number), context: Evaluators.context())

            expect(response.remoteConfigEvaluation.remoteConfigResult.reason) == DecisionReason.TYPE_MISMATCH
            expect(response.remoteConfigEvaluation.remoteConfigResult.value?.id) == 7
            expect(response.remoteConfigEvaluation.remoteConfigResult.value?.rawValue) == HackleValue.string("v")
        }

        it("requiredType과 값 타입이 일치하면 entity의 reason을 유지한다") {
            let localSut = makeEvaluator()
            let result = remoteConfigRemoteResult(value: RemoteConfigParameter.Value(id: 7, rawValue: HackleValue.string("v")), reason: DecisionReason.TARGET_RULE_MATCH)

            let response: RemoteConfigEvaluateResponse = try localSut.evaluate(request: request(result: result, requiredType: .string), context: Evaluators.context())

            expect(response.remoteConfigEvaluation.remoteConfigResult.reason) == DecisionReason.TARGET_RULE_MATCH
            expect(response.remoteConfigEvaluation.remoteConfigResult.value?.id) == 7
            expect(response.remoteConfigEvaluation.remoteConfigResult.value?.rawValue) == HackleValue.string("v")
        }

        it("entity의 value가 nil이면 타입 검사 없이 reason을 유지한다") {
            let localSut = makeEvaluator()
            let result = remoteConfigRemoteResult(value: nil, reason: DecisionReason.SDK_NOT_READY)

            let response: RemoteConfigEvaluateResponse = try localSut.evaluate(request: request(result: result, requiredType: .string), context: Evaluators.context())

            expect(response.remoteConfigEvaluation.remoteConfigResult.reason) == DecisionReason.SDK_NOT_READY
            expect(response.remoteConfigEvaluation.remoteConfigResult.value).to(beNil())
        }
    }
}
