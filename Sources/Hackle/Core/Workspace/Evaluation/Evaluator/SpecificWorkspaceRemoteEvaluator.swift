import Foundation

class SpecificWorkspaceRemoteEvaluator: WorkspaceRemoteEvaluator {

    private let client: WorkspaceRemoteEvaluateClient

    init(client: WorkspaceRemoteEvaluateClient) {
        self.client = client
    }

    func supports(scope: WorkspaceEvaluateScope) -> Bool {
        scope == .specific
    }

    func evaluate(request: WorkspaceEvaluateRequest) async throws -> WorkspaceEvaluateResponse {
        guard let request = request as? SpecificWorkspaceEvaluateRequest else {
            throw HackleError.error("Unsupported WorkspaceEvaluateRequest: \(type(of: request))")
        }
        let responseDto = try await client.evaluate(request: request.toDto())
        return try resolveResponse(dto: responseDto)
    }

    private func resolveResponse(dto: WorkspaceEvaluateResponseDto) throws -> WorkspaceEvaluateResponse {
        guard let evaluation = dto.evaluation else {
            throw HackleError.error("evaluation")
        }
        return WorkspaceEvaluateResponse.of(status: .full, dto: evaluation)
    }
}

class SpecificWorkspaceEvaluateRequest: WorkspaceEvaluateRequest {

    var scope: WorkspaceEvaluateScope {
        .specific
    }
    let context: WorkspaceEvaluateContext
    let targets: [Entity]

    init(context: WorkspaceEvaluateContext, targets: [Entity]) {
        self.context = context
        self.targets = targets
    }
}

private extension SpecificWorkspaceEvaluateRequest {

    func toDto() -> WorkspaceEvaluateRequestDto {
        WorkspaceEvaluateRequestDto(
            scope: WorkspaceEvaluateScope.specific.rawValue,
            policy: WorkspaceEvaluatePolicy.forceFull.rawValue,
            context: context.toDto(),
            entities: targets.map { it in
                EvaluateEntityDto(type: it.serviceType.rawValue, id: it.id, hash: nil)
            },
            current: nil
        )
    }
}
