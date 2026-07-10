import Foundation

protocol LocalEvaluateRequest: EvaluateRequest {
    var workspaceConfig: WorkspaceConfig { get }
}
