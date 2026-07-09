import Foundation

final class ExperimentRemoteEvaluateRequest: RemoteEvaluateRequest, ExperimentEvaluateRequest, CustomStringConvertible {

    let evaluationWorkspace: WorkspaceEvaluation
    let result: ExperimentRemoteEvaluateResult
    let user: HackleUser
    let record: Bool

    var workspace: Workspace { evaluationWorkspace }
    var entity: Entity { result }
    var remoteResult: RemoteEvaluateResult { result }
    var experiment: Experiment { result }

    private init(workspace: WorkspaceEvaluation, entity: ExperimentRemoteEvaluateResult, user: HackleUser, record: Bool) {
        self.evaluationWorkspace = workspace
        self.result = entity
        self.user = user
        self.record = record
    }

    var description: String {
        "ExperimentRemoteEvaluateRequest(type=\(result.type.rawValue), key=\(result.key))"
    }

    static func of(
        workspace: WorkspaceEvaluation,
        experiment: ExperimentRemoteEvaluateResult,
        user: HackleUser,
        record: Bool = true
    ) -> ExperimentRemoteEvaluateRequest {
        ExperimentRemoteEvaluateRequest(workspace: workspace, entity: experiment, user: user, record: record)
    }

    static func of(
        request: RemoteEvaluateRequest,
        experiment: ExperimentRemoteEvaluateResult
    ) -> ExperimentRemoteEvaluateRequest {
        ExperimentRemoteEvaluateRequest(
            workspace: request.evaluationWorkspace,
            entity: experiment,
            user: request.user,
            record: request.record
        )
    }
}
