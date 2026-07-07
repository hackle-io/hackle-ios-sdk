//
//  UserCohortFetcher.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation

protocol UserCohortFetcher {
    func fetch(user: User) async throws -> UserCohorts
}

class DefaultUserCohortFetcher: UserCohortFetcher {

    private let url: URL
    private let httpClient: HttpClient
    private let timeout: TimeInterval = 10 // watchdog mainthread crash 회피를 위해 10초 설정

    init(config: HackleConfig, httpClient: HttpClient) {
        self.url = URL(string: DefaultUserCohortFetcher.url(config: config))!
        self.httpClient = httpClient
    }

    private static func url(config: HackleConfig) -> String {
        "\(config.sdkUrl)/api/v1/cohorts"
    }

    func fetch(user: User) async throws -> UserCohorts {
        let request = try createRequest(user: user)
        let sample = TimerSample.start()
        let response = await httpClient.execute(request: request, timeout: timeout)
        ApiCallMetrics.record(operation: "get.cohorts", sample: sample, response: response)
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

    private func handleResponse(response: HttpResponse) throws -> UserCohorts {
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

        guard let dto = try? JSONDecoder().decode(UserCohortsResponseDto.self, from: responseBody) else {
            throw HackleError.error("Invalid format")
        }

        return UserCohorts.from(dto: dto)
    }
}
