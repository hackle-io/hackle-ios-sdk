import Foundation

final class RemoteConfigRemoteEvaluateRequest: RemoteEvaluateRequest, RemoteConfigEvaluateRequest, CustomStringConvertible {

    let evaluationWorkspace: WorkspaceEvaluation
    let result: RemoteConfigParameterRemoteEvaluateResult
    let user: HackleUser
    let record: Bool
    let requiredType: HackleValueType

    var workspace: Workspace { evaluationWorkspace }
    var entity: Entity { result }
    var remoteResult: RemoteEvaluateResult { result }
    var parameter: RemoteConfigParameter { result }

    private init(
        workspace: WorkspaceEvaluation,
        entity: RemoteConfigParameterRemoteEvaluateResult,
        user: HackleUser,
        record: Bool,
        requiredType: HackleValueType
    ) {
        self.evaluationWorkspace = workspace
        self.result = entity
        self.user = user
        self.record = record
        self.requiredType = requiredType
    }

    var description: String {
        "RemoteConfigRemoteEvaluateRequest(key=\(result.key))"
    }

    static func of(
        workspace: WorkspaceEvaluation,
        parameter: RemoteConfigParameterRemoteEvaluateResult,
        user: HackleUser,
        requiredType: HackleValueType,
        record: Bool = true
    ) -> RemoteConfigRemoteEvaluateRequest {
        RemoteConfigRemoteEvaluateRequest(workspace: workspace, entity: parameter, user: user, record: record, requiredType: requiredType)
    }
}
