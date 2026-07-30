import Foundation
import Quick
import Nimble
@testable import Hackle

class EvaluateProcessorSpecs: QuickSpec {
    override class func spec() {

        func createSut(eventProcessor: MockUserEventProcessor) -> EvaluateProcessor {
            EvaluateProcessor.create(
                context: HackleCoreContext(),
                clock: SystemClock.shared,
                eventProcessor: eventProcessor,
                overrideStorage: DelegatingManualOverrideStorage(storages: []),
                impressionStorage: DefaultInAppMessageImpressionStorage.create(suiteName: "EvaluateProcessorSpecs"),
                hiddenStorage: DefaultInAppMessageHiddenStorage.create(suiteName: "EvaluateProcessorSpecs")
            )
        }

        it("routes experiment remote request to remote evaluator (pass-through)") {
            let eventProcessor = MockUserEventProcessor()
            let sut = createSut(eventProcessor: eventProcessor)
            let result = experimentRemoteResult(id: 1, key: 10, reason: DecisionReason.TRAFFIC_ALLOCATED)
            let workspace = MockWorkspaceEvaluation()
            workspace.experimentResults = [result]
            let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: result, user: HackleUser.builder().build())

            let response = try sut.experiment(request)

            expect(response.experimentEvaluation.experimentResult.reason).to(equal(DecisionReason.TRAFFIC_ALLOCATED))
            // record=true 단건 경로 → 노출 이벤트 1회
            verify(exactly: 1) {
                eventProcessor.processMock
            }
        }

        it("does not record when request.record is false") {
            let eventProcessor = MockUserEventProcessor()
            let sut = createSut(eventProcessor: eventProcessor)
            let result = experimentRemoteResult(id: 1, key: 10)
            let workspace = MockWorkspaceEvaluation()
            let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: result, user: HackleUser.builder().build(), record: false)

            _ = try sut.experiment(request)

            verify(exactly: 0) {
                eventProcessor.processMock
            }
        }

        it("routes remoteconfig remote request to remote evaluator") {
            let eventProcessor = MockUserEventProcessor()
            let sut = createSut(eventProcessor: eventProcessor)
            let result = remoteConfigRemoteResult()
            let workspace = MockWorkspaceEvaluation()
            let request = RemoteConfigRemoteEvaluateRequest.of(workspace: workspace, entity: result, user: HackleUser.builder().build(), requiredType: .string)

            let response = try sut.remoteConfig(request)

            expect(response.remoteConfigEvaluation.remoteConfigResult.value?.id).to(equal(7))
        }
    }
}
