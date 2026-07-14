import Foundation

protocol WorkspaceRemoteEvaluator: AnyObject {
    func supports(scope: WorkspaceEvaluateScope) -> Bool
    func evaluate(request: WorkspaceEvaluateRequest) async throws -> WorkspaceEvaluateResponse
}
