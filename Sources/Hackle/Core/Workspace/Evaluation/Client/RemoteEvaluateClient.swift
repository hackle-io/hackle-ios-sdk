import Foundation

class RemoteEvaluateClient {

    private static let WORKSPACE_EVALUATE_PATH = "/api/v1/workspace-evaluate"
    private static let ENTITY_EVALUATE_PATH = "/api/v1/entity-evaluate"
    // 초기 sync 중 coreQueue가 suspend되므로(813404f) 기본 60초 폴백 금지. iOS 관례(UserCohortFetcher) 10초.
    private static let TIMEOUT_INTERVAL: TimeInterval = 10

    private let workspaceEndpoint: URL
    private let entityEndpoint: URL
    private let httpClient: HttpClient

    init(sdkUrl: URL, httpClient: HttpClient) {
        self.workspaceEndpoint = sdkUrl.appendingPathComponent(RemoteEvaluateClient.WORKSPACE_EVALUATE_PATH)
        self.entityEndpoint = sdkUrl.appendingPathComponent(RemoteEvaluateClient.ENTITY_EVALUATE_PATH)
        self.httpClient = httpClient
    }

    func evaluateIfModified(request: WorkspaceEvaluateRequestDto) async throws -> WorkspaceEvaluateResponseDto? {
        let response = try await execute(url: workspaceEndpoint, body: request.toBody(), operation: "workspace.remote.evaluate")
        return try handleWorkspaceResponse(response: response)
    }

    func evaluateEntities(request: EntityEvaluateRequestDto) async throws -> EntityEvaluateResponseDto {
        let response = try await execute(url: entityEndpoint, body: request.toBody(), operation: "entity.remote.evaluate")
        return try handleResponse(response: response)
    }

    private func execute(url: URL, body: [String: Any], operation: String) async throws -> HttpResponse {
        guard let data = Json.serialize(body) else {
            throw HackleError.error("Failed to serialize \(operation) request")
        }
        let httpRequest = HttpRequest.post(url: url, body: data)
        return await ApiCallMetrics.record(operation: operation) {
            await self.httpClient.execute(request: httpRequest, timeout: RemoteEvaluateClient.TIMEOUT_INTERVAL)
        }
    }

    private func handleWorkspaceResponse(response: HttpResponse) throws -> WorkspaceEvaluateResponseDto? {
        if response.isNoContent {
            return nil
        }
        return try handleResponse(response: response)
    }

    private func handleResponse<T: Decodable>(response: HttpResponse) throws -> T {
        if let error = response.error {
            throw error
        }
        guard response.isSuccessful else {
            throw HackleError.error("Http status code: \(response.statusCode ?? -1)")
        }
        guard let data = response.data else {
            throw HackleError.error("Response body is empty")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
