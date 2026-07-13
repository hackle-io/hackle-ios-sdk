import Foundation

class WorkspaceRemoteEvaluateClient {

    private static let EVALUATE_PATH = "/api/v1/evaluate"

    private let endpoint: URL
    private let httpClient: HttpClient

    init(sdkUrl: URL, httpClient: HttpClient) {
        self.endpoint = sdkUrl.appendingPathComponent(WorkspaceRemoteEvaluateClient.EVALUATE_PATH)
        self.httpClient = httpClient
    }

    func evaluate(request: WorkspaceEvaluateRequestDto) async throws -> WorkspaceEvaluateResponseDto {
        guard let body = Json.serialize(request.toBody()) else {
            throw HackleError.error("Failed to serialize WorkspaceEvaluateRequest")
        }
        let httpRequest = HttpRequest.post(url: endpoint, body: body)
        let sample = TimerSample.start()
        let response = await httpClient.execute(request: httpRequest)
        ApiCallMetrics.record(operation: "workspace.remote.evaluate", sample: sample, response: response)
        return try handleResponse(response: response)
    }

    private func handleResponse(response: HttpResponse) throws -> WorkspaceEvaluateResponseDto {
        if let error = response.error {
            throw error
        }
        guard response.isSuccessful else {
            throw HackleError.error("Http status code: \(response.statusCode ?? -1)")
        }
        guard let data = response.data else {
            throw HackleError.error("Response body is empty")
        }
        return try JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data)
    }
}
