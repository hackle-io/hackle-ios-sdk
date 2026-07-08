//
//  HttpWorkspaceConfigFetcher.swift
//  Hackle
//

import Foundation


protocol HttpWorkspaceConfigFetcher {
    func fetchIfModified(lastModified: String?) async throws -> WorkspaceConfigContext?
}

class DefaultHttpWorkspaceConfigFetcher: HttpWorkspaceConfigFetcher {

    private let url: URL
    private let httpClient: HttpClient

    init(config: HackleConfig, sdk: Sdk, httpClient: HttpClient) {
        self.url = URL(string: DefaultHttpWorkspaceConfigFetcher.url(config: config, sdk: sdk))!
        self.httpClient = httpClient
    }

    private static func url(config: HackleConfig, sdk: Sdk) -> String {
        "\(config.sdkUrl)/api/v2/workspaces/\(sdk.key)/config"
    }

    func fetchIfModified(lastModified: String? = nil) async throws -> WorkspaceConfigContext? {
        let request = createRequest(lastModified: lastModified)
        return try await execute(request: request)
    }

    private func createRequest(lastModified: String?) -> HttpRequest {
        if let lastModified = lastModified {
            return HttpRequest.get(url: url, headers: HttpHeader.ifModifiedSince.with(value: lastModified))
        } else {
            return HttpRequest.get(url: url)
        }
    }

    private func execute(request: HttpRequest) async throws -> WorkspaceConfigContext? {
        let sample = TimerSample.start()
        let response = await httpClient.execute(request: request)
        ApiCallMetrics.record(operation: "get.workspace", sample: sample, response: response)
        return try handleResponse(response: response)
    }

    private func handleResponse(response: HttpResponse) throws -> WorkspaceConfigContext? {
        if let error = response.error {
            throw error
        }

        guard let urlResponse = response.urlResponse as? HTTPURLResponse else {
            throw HackleError.error("Response is empty")
        }

        if urlResponse.isNotModified {
            Log.debug("Workspace is not modified")
            return nil
        }

        guard urlResponse.isSuccessful else {
            throw HackleError.error("Http status code: \(urlResponse.statusCode)")
        }

        guard let responseBody = response.data else {
            throw HackleError.error("Response body is empty")
        }

        let lastModified = urlResponse.header(.lastModified)
        guard let workspaceDto = try? JSONDecoder().decode(WorkspaceConfigDto.self, from: responseBody) else {
            throw HackleError.error("Invalid format")
        }

        Log.debug("Workspace fetched")

        return WorkspaceConfigContext.of(dto: workspaceDto, modifiedAt: lastModified)
    }
}
