import Foundation

protocol RemoteEvaluateRequest: EvaluateRequest {
    var evaluationWorkspace: WorkspaceEvaluation { get }
    var remoteResult: RemoteEvaluateResult { get }
}

extension RemoteEvaluateRequest {
    var workspace: Workspace { evaluationWorkspace }
}
