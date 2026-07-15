import Foundation

protocol WorkspaceEvaluateRequest {
    var scope: WorkspaceEvaluateScope { get }
    var context: RemoteEvaluateContext { get }
}
