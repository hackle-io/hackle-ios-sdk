//
//  HttpWorkspaceFetcher.swift
//  Hackle
//

import Foundation


protocol HttpWorkspaceFetcher {
    func fetchIfModified(lastModified: String?) async throws -> WorkspaceConfigResponse?
}

class DefaultHttpWorkspaceFetcher: HttpWorkspaceFetcher {

    private let url: URL
    private let httpClient: HttpClient

    init(config: HackleConfig, sdk: Sdk, httpClient: HttpClient) {
        self.url = URL(string: DefaultHttpWorkspaceFetcher.url(config: config, sdk: sdk))!
        self.httpClient = httpClient
    }

    private static func url(config: HackleConfig, sdk: Sdk) -> String {
        "\(config.sdkUrl)/api/v2/workspaces/\(sdk.key)/config"
    }

    func fetchIfModified(lastModified: String? = nil) async throws -> WorkspaceConfigResponse? {
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

    private func execute(request: HttpRequest) async throws -> WorkspaceConfigResponse? {
        let sample = TimerSample.start()
        return try await withCheckedThrowingContinuation { continuation in
            httpClient.execute(request: request) { [weak self] response in
                guard let self = self else {
                    continuation.resume(throwing: HackleError.error("Failed to fetch workspace: instance deallocated"))
                    return
                }
                ApiCallMetrics.record(operation: "get.workspace", sample: sample, response: response)
                do {
                    let workspace = try self.handleResponse(response: response)
                    continuation.resume(returning: workspace)
                } catch let error {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func handleResponse(response: HttpResponse) throws -> WorkspaceConfigResponse? {
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

        return WorkspaceConfigResponse(lastModified: lastModified, config: workspaceDto)
    }
}
