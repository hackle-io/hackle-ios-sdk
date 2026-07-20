//
//  UserTargetFetcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//

import Foundation

protocol UserTargetEventFetcher {
    func fetch(user: User) async throws -> UserTargetEvents
}

class DefaultUserTargetEventFetcher: UserTargetEventFetcher {

    private let url: URL
    private let httpClient: HttpClient
    private let timeout: TimeInterval = 10 // watchdog mainthread crash 회피를 위해 10초 설정

    init(config: HackleConfig, httpClient: HttpClient) {
        self.url = URL(string: DefaultUserTargetEventFetcher.url(config: config))!
        self.httpClient = httpClient
    }

    private static func url(config: HackleConfig) -> String {
        "\(config.sdkUrl)/api/v1/user-targets"
    }

    func fetch(user: User) async throws -> UserTargetEvents {
        let request = try createRequest(user: user)
        let response = await ApiCallMetrics.record(operation: "get.user-targets") {
            await self.httpClient.execute(request: request, timeout: self.timeout)
        }
        return try handleResponse(response: response)
    }

    private func createRequest(user: User) throws -> HttpRequest {
        let identifiers = user.resolvedIdentifiers
        guard let data = Json.serialize(["identifiers": identifiers]) else {
            throw HackleError.error("Failed to serialize identifiers: \(identifiers)")
        }
        let headers = ["X-HACKLE-USER": Base64.encodeUrl(data)]
        return HttpRequest.get(url: self.url, headers: headers)
    }

    private func handleResponse(response: HttpResponse) throws -> UserTargetEvents {
        if let error = response.error {
            throw error
        }

        guard let urlResponse = response.urlResponse as? HTTPURLResponse else {
            throw HackleError.error("Response is empty")
        }

        guard urlResponse.isSuccessful else {
            throw HackleError.error("Http status code: \(urlResponse.statusCode)")
        }

        guard let responseBody = response.data else {
            throw HackleError.error("Response body is empty")
        }

        guard let dto = try? JSONDecoder().decode(UserTargetResponseDto.self, from: responseBody) else {
            throw HackleError.error("Invalid format")
        }

        return UserTargetEvents.from(dto: dto)
    }
}


