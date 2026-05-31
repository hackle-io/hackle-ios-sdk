//
//  HttpWorkspaceFetcher.swift
//  Hackle
//
//  Created by yong on 2023/10/01.
//

import Foundation


protocol HttpWorkspaceFetcher {
    func fetchIfModified(lastModified: String?, completion: @escaping (Result<WorkspaceConfig?, Error>) -> ())
}

class DefaultHttpWorkspaceFetcher: HttpWorkspaceFetcher {

    private let url: URL
    private let httpClient: HttpClient

    init(config: HackleConfig, sdk: Sdk, httpClient: HttpClient) {
        let urlString = DefaultHttpWorkspaceFetcher.url(config: config, sdk: sdk)
        guard let url = URL(string: urlString) else {
            fatalError("Invalid Hackle workspace url: \(urlString)")
        }
        self.url = url
        self.httpClient = httpClient
    }

    private static func url(config: HackleConfig, sdk: Sdk) -> String {
        // Percent-encode the SDK key: it is raw developer input (Hackle.initialize)
        // and a stray whitespace/newline made the strict iOS 13-16 URL parser return
        // nil, crashing the force-unwrap before any request.
        let key = sdk.key.trimmingCharacters(in: .whitespacesAndNewlines)
        let encodedKey = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        return "\(config.sdkUrl)/api/v2/workspaces/\(encodedKey)/config"
    }

    func fetchIfModified(lastModified: String? = nil, completion: @escaping (Result<WorkspaceConfig?, Error>) -> ()) {
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

    private func execute(request: HttpRequest, completion: @escaping (Result<WorkspaceConfig?, Error>) -> ()) {
        let sample = TimerSample.start()
        httpClient.execute(request: request) { [weak self] response in
            guard let self = self else {
                completion(.failure(HackleError.error("Failed to fetch workspace: instance deallocated")))
                return
            }
            ApiCallMetrics.record(operation: "get.workspace", sample: sample, response: response)
            do {
                let workspace = try self.handleResponse(response: response)
                completion(.success(workspace))
            } catch let error {
                completion(.failure(error))
            }
        }
    }

    private func handleResponse(response: HttpResponse) throws -> WorkspaceConfig? {
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

        return WorkspaceConfig(lastModified: lastModified, config: workspaceDto)
    }
}
