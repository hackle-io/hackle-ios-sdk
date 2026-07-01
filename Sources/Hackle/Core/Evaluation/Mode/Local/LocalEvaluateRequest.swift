import Foundation

protocol LocalEvaluateRequest: EvaluateRequest {
    var workspace: WorkspaceConfig { get }
    var entity: ConfigEntity { get }
}
