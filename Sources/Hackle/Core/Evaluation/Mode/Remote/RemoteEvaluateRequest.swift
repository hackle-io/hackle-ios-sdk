import Foundation

protocol RemoteEvaluateRequest: EvaluateRequest {
    var evaluationWorkspace: WorkspaceEvaluation { get }
    var remoteResult: RemoteEvaluateResult { get }
}
