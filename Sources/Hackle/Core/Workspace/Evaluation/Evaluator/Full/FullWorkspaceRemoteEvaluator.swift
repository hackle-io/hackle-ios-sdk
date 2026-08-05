import Foundation

class FullWorkspaceRemoteEvaluator: WorkspaceRemoteEvaluator {

    private let client: RemoteEvaluateClient

    init(client: RemoteEvaluateClient) {
        self.client = client
    }

    func evaluate(request: FullWorkspaceEvaluateRequest) async throws -> FullWorkspaceEvaluateResponse {
        let responseDto = try await client.evaluateIfModified(request: request.toDto())
        return try await resolveResponse(request: request, response: responseDto)
    }

    private func resolveResponse(
        request: FullWorkspaceEvaluateRequest,
        response: WorkspaceEvaluateResponseDto?
    ) async throws -> FullWorkspaceEvaluateResponse {
        guard let response = response else { // NOT_MODIFIED (HTTP 204)
            guard let base = request.base else {
                throw HackleError.error("request.base")
            }
            return FullWorkspaceEvaluateResponse(context: base)
        }
        guard let status = WorkspaceEvaluateStatus(rawValue: response.status) else {
            throw HackleError.error("Unsupported WorkspaceEvaluateStatus: \(response.status)")
        }
        switch status {
        case .full:
            return try resolveFull(request: request, response: response)
        case .delta:
            return try await resolveDelta(request: request, response: response)
        }
    }

    private func resolveFull(
        request: FullWorkspaceEvaluateRequest,
        response: WorkspaceEvaluateResponseDto
    ) throws -> FullWorkspaceEvaluateResponse {
        guard let evaluation = response.full else {
            throw HackleError.error("response.full")
        }
        let context = WorkspaceEvaluationContext.of(
            key: request.context.key,
            dto: evaluation,
            fullEvaluatedAt: evaluation.metadata.evaluatedAt
        )
        return FullWorkspaceEvaluateResponse(context: context)
    }

    private func resolveDelta(
        request: FullWorkspaceEvaluateRequest,
        response: WorkspaceEvaluateResponseDto
    ) async throws -> FullWorkspaceEvaluateResponse {
        guard let base = request.base else {
            throw HackleError.error("request.base")
        }
        guard let delta = response.delta else {
            throw HackleError.error("response.delta")
        }

        let mergedEvaluation = WorkspaceEvaluationMerger.merge(evaluation: base.dto, delta: delta)
        let mergedHash = WorkspaceEvaluationMerger.hash(results: mergedEvaluation.results)

        if mergedHash != delta.metadata.hash {
            guard let fullResponse = try await client.evaluateIfModified(request: request.toForceFull().toDto()) else {
                throw HackleError.error("response")
            }
            return try resolveFull(request: request, response: fullResponse)
        }

        let context = WorkspaceEvaluationContext.of(
            key: base.key,
            dto: mergedEvaluation,
            fullEvaluatedAt: base.fullEvaluatedAt
        )
        return FullWorkspaceEvaluateResponse(context: context)
    }
}
