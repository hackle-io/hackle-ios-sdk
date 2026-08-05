import Foundation

protocol WorkspaceRemoteEvaluator: AnyObject {
    associatedtype Request: WorkspaceEvaluateRequest
    associatedtype Response: WorkspaceEvaluateResponse
    func evaluate(request: Request) async throws -> Response
}
