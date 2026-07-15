import Foundation

class AllWorkspaceRemoteEvaluator: WorkspaceRemoteEvaluator {

    private let client: WorkspaceRemoteEvaluateClient

    init(client: WorkspaceRemoteEvaluateClient) {
        self.client = client
    }

    func supports(scope: WorkspaceEvaluateScope) -> Bool {
        scope == .all
    }

    func evaluate(request: WorkspaceEvaluateRequest) async throws -> WorkspaceEvaluateResponse {
        guard let request = request as? AllWorkspaceEvaluateRequest else {
            throw HackleError.error("Unsupported WorkspaceEvaluateRequest: \(type(of: request))")
        }
        let requestDto = createRequestDto(request: request)
        let responseDto = try await client.evaluate(request: requestDto)
        return try await resolveResponse(request: request, response: responseDto)
    }

    private func createRequestDto(request: AllWorkspaceEvaluateRequest) -> WorkspaceEvaluateRequestDto {
        if let record = request.record {
            return request.toAutoDto(record: record)
        } else {
            return request.toFullDto()
        }
    }

    private func resolveResponse(
        request: AllWorkspaceEvaluateRequest,
        response: WorkspaceEvaluateResponseDto
    ) async throws -> WorkspaceEvaluateResponse {
        guard let status = WorkspaceEvaluateStatus(rawValue: response.status) else {
            throw HackleError.error("Unsupported WorkspaceEvaluateStatus: \(response.status)")
        }
        switch status {
        case .full:
            return try resolveFull(dto: response)
        case .delta:
            return try await resolveDelta(request: request, response: response)
        case .notModified:
            return WorkspaceEvaluateResponse.notModified()
        }
    }

    private func resolveFull(dto: WorkspaceEvaluateResponseDto) throws -> WorkspaceEvaluateResponse {
        guard let evaluation = dto.evaluation else {
            throw HackleError.error("evaluation")
        }
        return WorkspaceEvaluateResponse.of(status: .full, dto: evaluation)
    }

    private func resolveDelta(
        request: AllWorkspaceEvaluateRequest,
        response: WorkspaceEvaluateResponseDto
    ) async throws -> WorkspaceEvaluateResponse {
        guard let currentEvaluation = request.record?.dto else {
            throw HackleError.error("request evaluation")
        }
        guard let responseEvaluation = response.evaluation else {
            throw HackleError.error("response evaluation")
        }

        let mergedEvaluation = try WorkspaceEvaluationMerger.merge(evaluation: currentEvaluation, response: response)
        let mergedHash = WorkspaceEvaluationMerger.hash(results: mergedEvaluation.results)

        if mergedHash != responseEvaluation.metadata.results.hash {
            let requestDto = request.toFullDto()
            let fullResponse = try await client.evaluate(request: requestDto)
            return try resolveFull(dto: fullResponse)
        }

        return WorkspaceEvaluateResponse.of(status: .full, dto: mergedEvaluation)
    }
}

class AllWorkspaceEvaluateRequest: WorkspaceEvaluateRequest {

    var scope: WorkspaceEvaluateScope {
        .all
    }
    let context: RemoteEvaluateContext
    let record: WorkspaceEvaluationContext?

    init(context: RemoteEvaluateContext, record: WorkspaceEvaluationContext?) {
        self.context = context
        self.record = record
    }
}

private extension AllWorkspaceEvaluateRequest {

    func toFullDto() -> WorkspaceEvaluateRequestDto {
        WorkspaceEvaluateRequestDto(
            scope: WorkspaceEvaluateScope.all.rawValue,
            policy: WorkspaceEvaluatePolicy.forceFull.rawValue,
            context: context.toDto(),
            entities: [],
            current: nil
        )
    }

    func toAutoDto(record: WorkspaceEvaluationContext) -> WorkspaceEvaluateRequestDto {
        WorkspaceEvaluateRequestDto(
            scope: WorkspaceEvaluateScope.all.rawValue,
            policy: WorkspaceEvaluatePolicy.auto.rawValue,
            context: context.toDto(),
            entities: record.dto.results.map { it in
                EvaluateEntityDto(type: it.type, id: it.id, hash: it.hash)
            },
            current: record.dto.metadata
        )
    }
}
