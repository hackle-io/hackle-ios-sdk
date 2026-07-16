import Foundation

class PartialWorkspaceRemoteEvaluator: WorkspaceRemoteEvaluator {

    private let client: RemoteEvaluateClient

    init(client: RemoteEvaluateClient) {
        self.client = client
    }

    func evaluate(request: PartialWorkspaceEvaluateRequest) async throws -> PartialWorkspaceEvaluateResponse {
        let responseDto = try await client.evaluateEntities(request: request.toDto())
        let evaluation = DefaultWorkspaceEvaluation.from(dto: responseDto.evaluation)
        return PartialWorkspaceEvaluateResponse(evaluation: evaluation)
    }
}
