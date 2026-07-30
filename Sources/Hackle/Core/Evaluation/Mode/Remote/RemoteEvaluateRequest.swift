import Foundation

protocol RemoteEvaluateRequest: EvaluateRequest {
    var evaluationWorkspace: WorkspaceEvaluation { get }
    var remoteResult: any RemoteEvaluateResult { get }
}

extension RemoteEvaluateRequest {
    var workspace: Workspace { evaluationWorkspace }
}
