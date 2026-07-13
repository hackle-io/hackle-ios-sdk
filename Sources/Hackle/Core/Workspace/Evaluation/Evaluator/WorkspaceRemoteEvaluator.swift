import Foundation

// Kotlin 제네릭 <REQUEST: WorkspaceEvaluateRequest>는 비제네릭 protocol + 구현 내부 다운캐스트로 대응 (D5)
protocol WorkspaceRemoteEvaluator: AnyObject {
    func supports(scope: WorkspaceEvaluateScope) -> Bool
    func evaluate(request: WorkspaceEvaluateRequest) async throws -> WorkspaceEvaluateResponse
}
