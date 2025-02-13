//
//  UserTargetFetcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//

import Foundation

protocol UserTargetEventsFetcher {
    func fetch(user: User, completion: @escaping (Result<UserTargetEvents, Error>) -> ())
}

class DefaultUserTargetEventsFetcher: UserTargetEventsFetcher {

    private let url: URL
    private let httpClient: HttpClient
    private let timeout: TimeInterval = 2 // watchdog mainthread crash 회피를 위해 2초 설정

    init(config: HackleConfig, httpClient: HttpClient) {
        self.url = URL(string: DefaultUserTargetEventsFetcher.url(config: config))!
        self.httpClient = httpClient
    }

    private static func url(config: HackleConfig) -> String {
        "\(config.sdkUrl)/api/v1/user-targets"
    }

    func fetch(user: User, completion: @escaping (Result<UserTargetEvents, Error>) -> ()) {
        do {
            let request = try createRequest(user: user)
            let sample = TimerSample.start()
            httpClient.execute(request: request, timeout: timeout) { [weak self] response in
                guard let self = self else {
                    completion(.failure(HackleError.error("Failed to fetch user target: instance deallocated")))
                    return
                }
                ApiCallMetrics.record(operation: "get.user-targets", sample: sample, response: response)
                do {
                    let userTargets = try self.handleResponse(response: response)
                    completion(.success(userTargets))
                } catch let error {
                    completion(.failure(error))
                }
            }
        } catch let error {
            completion(.failure(error))
        }
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

class UserTargetResponseDto: Codable {
    var events: [TargetEvent]
}
