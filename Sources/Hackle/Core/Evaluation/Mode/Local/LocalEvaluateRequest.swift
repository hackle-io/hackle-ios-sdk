import Foundation

protocol LocalEvaluateRequest: EvaluateRequest {
    var workspaceConfig: WorkspaceConfig { get }
}

extension LocalEvaluateRequest {
    var workspace: Workspace { workspaceConfig }
}
