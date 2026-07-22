import Foundation
import Quick
import Nimble
@testable import Hackle

class RemoteEvaluatorSpecs: QuickSpec {
    override class func spec() {

        describe("RemoteEvaluator.doEvaluate") {

            func sut(workspace: WorkspaceEvaluation, references: [Entity]) -> (StubRemoteEvaluator, StubRemoteEvaluateRequest) {
                let request = StubRemoteEvaluateRequest(
                    evaluationWorkspace: workspace,
                    result: experimentRemoteResult(id: 1, key: 10, references: references)
                )
                return (StubRemoteEvaluator(), request)
            }

            it("resolves references from workspace into context before remoteEvaluate") {
                let referenced = experimentRemoteResult(id: 99, key: 990)
                let workspace = MockWorkspaceEvaluation()
                workspace.experimentResults = [referenced]
                let (evaluator, request) = sut(workspace: workspace, references: [DefaultEntity(serviceType: .abTest, id: 99)])
                let context = Evaluators.context()

                let _: StubEvaluateResponse = try evaluator.evaluate(request: request, context: context)

                expect(context.references.count).to(equal(1))
                expect(context.get(referenced)?.entity.entityKey).to(equal(referenced.entityKey))
                expect(evaluator.remoteEvaluateCount).to(equal(1))
            }

            it("skips references already in context") {
                let referenced = experimentRemoteResult(id: 99, key: 990)
                let workspace = MockWorkspaceEvaluation()
                workspace.experimentResults = [referenced]
                let (evaluator, request) = sut(workspace: workspace, references: [DefaultEntity(serviceType: .abTest, id: 99)])
                let context = Evaluators.context()
                context.add(referenced.toEvaluation())

                let _: StubEvaluateResponse = try evaluator.evaluate(request: request, context: context)

                expect(context.references.count).to(equal(1))
            }

            it("skips references not present in workspace") {
                let workspace = MockWorkspaceEvaluation()
                let (evaluator, request) = sut(workspace: workspace, references: [DefaultEntity(serviceType: .abTest, id: 99)])
                let context = Evaluators.context()

                let _: StubEvaluateResponse = try evaluator.evaluate(request: request, context: context)

                expect(context.references.count).to(equal(0))
                expect(evaluator.remoteEvaluateCount).to(equal(1))
            }
        }
    }

    final class StubRemoteEvaluateRequest: RemoteEvaluateRequest {
        let evaluationWorkspace: WorkspaceEvaluation
        let result: ExperimentRemoteEvaluateResult
        let user: HackleUser = HackleUser.builder().build()
        let record: Bool = false

        var entity: Entity { result }
        var remoteResult: any RemoteEvaluateResult { result }

        init(evaluationWorkspace: WorkspaceEvaluation, result: ExperimentRemoteEvaluateResult) {
            self.evaluationWorkspace = evaluationWorkspace
            self.result = result
        }
    }

    final class StubEvaluateResponse: EvaluateResponse {
        let user: HackleUser = HackleUser.builder().build()
        let workspace: Workspace = MockWorkspaceEvaluation()
        let evaluation: Evaluation
        let references: [Evaluation] = []
        init(evaluation: Evaluation) {
            self.evaluation = evaluation
        }
    }

    final class StubRemoteEvaluator: RemoteEvaluator {
        typealias Request = StubRemoteEvaluateRequest
        typealias Response = StubEvaluateResponse

        let eventRecorder: EvaluationEventRecorder = EvaluationEventRecorder(
            eventFactory: EvaluationEventFactory(clock: SystemClock.shared),
            eventProcessor: MockUserEventProcessor()
        )
        private(set) var remoteEvaluateCount = 0

        func remoteEvaluate(request: StubRemoteEvaluateRequest, context: EvaluatorContext) throws -> StubEvaluateResponse {
            remoteEvaluateCount += 1
            return StubEvaluateResponse(evaluation: request.result.toEvaluation())
        }
    }
}
