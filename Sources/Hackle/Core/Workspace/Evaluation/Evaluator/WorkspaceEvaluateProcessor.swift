import Foundation

class WorkspaceEvaluateProcessor {

    private let evaluatorFactory: WorkspaceRemoteEvaluatorFactory

    init(evaluatorFactory: WorkspaceRemoteEvaluatorFactory) {
        self.evaluatorFactory = evaluatorFactory
    }

    func process(request: WorkspaceEvaluateRequest) async throws -> WorkspaceEvaluateResponse {
        let evaluator = try evaluatorFactory.get(scope: request.scope)
        return try await evaluator.evaluate(request: request)
    }
}
