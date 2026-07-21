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
        let response = await ApiCallMetrics.record(operation: "get.workspace") {
            await self.httpClient.execute(request: request)
        }
        return try handleResponse(response: response)
    }

    private func handleResponse(response: HttpResponse) throws -> WorkspaceConfigContext? {
        if let error = response.error {
            throw error
        }
        guard let statusCode = response.statusCode else {
            throw HackleError.error("Response is empty")
        }
        if response.isNotModified {
            Log.debug("Workspace is not modified")
            return nil
        }
        guard response.isSuccessful else {
            throw HackleError.error("Http status code: \(statusCode)")
        }
        guard let responseBody = response.data else {
            throw HackleError.error("Response body is empty")
        }
        let lastModified = response.header(.lastModified)
        guard let workspaceDto = try? JSONDecoder().decode(WorkspaceConfigDto.self, from: responseBody) else {
            throw HackleError.error("Invalid format")
        }
        Log.debug("Workspace fetched")
        return WorkspaceConfigContext.of(dto: workspaceDto, modifiedAt: lastModified)
    }
}
