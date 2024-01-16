//
//  HttpWorkspaceFetcher.swift
//  Hackle
//
//  Created by yong on 2023/10/01.
//

import Foundation


protocol HttpWorkspaceFetcher {
    func fetchIfModified(lastModified: String?, completion: @escaping (Result<WorkspaceConfigDto?, Error>) -> ())
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

    func fetchIfModified(lastModified: String? = nil, completion: @escaping (Result<WorkspaceConfigDto?, Error>) -> ()) {
        let request = createRequest(lastModified: lastModified)
        execute(request: request, completion: completion)
    }

    private func createRequest(lastModified: String?) -> HttpRequest {
        if let lastModified = lastModified {
            return HttpRequest.get(url: url, headers: HttpHeader.ifModifiedSince.with(value: lastModified))
        } else {
            return HttpRequest.get(url: url)
        }
    }

    private func execute(request: HttpRequest, completion: @escaping (Result<WorkspaceConfigDto?, Error>) -> ()) {
        let sample = TimerSample.start()
        httpClient.execute(request: request) { response in
            ApiCallMetrics.record(operation: "get.workspace", sample: sample, response: response)
            do {
                let workspace = try self.handleResponse(response: response)
                completion(.success(workspace))
            } catch let error {
                completion(.failure(error))
            }
        }
    }

    private func handleResponse(response: HttpResponse) throws -> WorkspaceConfigDto? {
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

        guard let workspaceDto = try? JSONDecoder().decode(WorkspaceConfigDto.self, from: responseBody) else {
            throw HackleError.error("Invalid format")
        }
        
        let lastModified = urlResponse.header(.lastModified)
        workspaceDto.lastModified = lastModified

        Log.debug("Workspace fetched")

        return workspaceDto
    }
}
