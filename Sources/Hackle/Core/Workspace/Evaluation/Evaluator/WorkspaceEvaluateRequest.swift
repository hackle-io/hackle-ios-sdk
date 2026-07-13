import Foundation

protocol WorkspaceEvaluateRequest {
    var scope: WorkspaceEvaluateScope { get }
    var context: WorkspaceEvaluateContext { get }
}
