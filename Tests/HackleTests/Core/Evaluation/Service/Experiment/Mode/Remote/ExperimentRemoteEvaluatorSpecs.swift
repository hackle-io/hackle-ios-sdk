import Foundation
import Quick
import Nimble
@testable import Hackle

class ExperimentRemoteEvaluatorSpecs: QuickSpec {
    override class func spec() {

        var eventProcessor: MockUserEventProcessor!
        var sut: ExperimentRemoteEvaluator!

        beforeEach {
            eventProcessor = MockUserEventProcessor()
            sut = ExperimentRemoteEvaluator(
                eventRecorder: EvaluationEventRecorder(
                    eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
                    eventProcessor: eventProcessor
                )
            )
        }

        it("supports only ExperimentRemoteEvaluateRequest") {
            let workspace = MockWorkspaceEvaluation()
            let request = ExperimentRemoteEvaluateRequest.of(
                workspace: workspace,
                entity: experimentRemoteResult(id: 1, key: 10),
                user: HackleUser.builder().build()
            )
            expect(sut.supports(request: request)).to(beTrue())
        }

        it("remoteEvaluate passes through the server-evaluated result") {
            let result = experimentRemoteResult(id: 1, key: 10, reason: DecisionReason.TRAFFIC_ALLOCATED)
            let workspace = MockWorkspaceEvaluation()
            workspace.experimentResults = [result]
            let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: result, user: HackleUser.builder().build())

            let response: ExperimentEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())

            expect(response.experimentEvaluation.experiment.entityKey).to(equal(result.entityKey))
            expect(response.experimentEvaluation.experimentResult.variation.key).to(equal("B"))
            expect(response.experimentEvaluation.experimentResult.reason).to(equal(DecisionReason.TRAFFIC_ALLOCATED))
        }

        it("실험 평가 시 AB_TEST reference의 TRAFFIC_ALLOCATED를 사유 변경 없이 컨텍스트에 올린다") {
            let reference = experimentRemoteResult(id: 2, key: 20, type: .abTest, reason: DecisionReason.TRAFFIC_ALLOCATED)
            let main = experimentRemoteResult(id: 1, key: 10, type: .abTest, reason: DecisionReason.TRAFFIC_ALLOCATED, references: [reference])
            let workspace = MockWorkspaceEvaluation()
            workspace.experimentResults = [main, reference]
            let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: main, user: HackleUser.builder().build())
            let context = Evaluators.context()
            let sut = ExperimentRemoteEvaluator(
                eventRecorder: EvaluationEventRecorder(
                    eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
                    eventProcessor: MockUserEventProcessor()
                )
            )

            let _: ExperimentEvaluateResponse = try sut.evaluate(request: request, context: context)

            let added = context.references.compactMap { $0 as? ExperimentEvaluation }.first!
            expect(added.experimentResult.reason) == DecisionReason.TRAFFIC_ALLOCATED
        }

        it("record delegates to eventRecorder") {
            let result = experimentRemoteResult(id: 1, key: 10)
            let workspace = MockWorkspaceEvaluation()
            let request = ExperimentRemoteEvaluateRequest.of(workspace: workspace, entity: result, user: HackleUser.builder().build())
            let response: ExperimentEvaluateResponse = try sut.evaluate(request: request, context: Evaluators.context())

            sut.record(request: request, response: response)

            verify(exactly: 1) {
                eventProcessor.processMock
            }
        }
    }
}
