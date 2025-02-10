//
//  UserCohortFetcher.swift
//  Hackle
//
//  Created by yong on 2023/10/03.
//

import Foundation

protocol UserCohortFetcher {
    func fetch(user: User, completion: @escaping (Result<UserCohorts, Error>) -> ())
}

class DefaultUserCohortFetcher: UserCohortFetcher {

    private let url: URL
    private let httpClient: HttpClient

    init(config: HackleConfig, httpClient: HttpClient) {
        self.url = URL(string: DefaultUserCohortFetcher.url(config: config))!
        self.httpClient = httpClient
    }

    private static func url(config: HackleConfig) -> String {
        "\(config.sdkUrl)/api/v1/cohorts"
    }

    func fetch(user: User, completion: @escaping (Result<UserCohorts, Error>) -> ()) {
        do {
            let request = try createRequest(user: user)
            let sample = TimerSample.start()
            httpClient.execute(request: request) { [weak self] response in
                guard let self = self else {
                    completion(.failure(HackleError.error("Failed to fetch cohorts: instance deallocated")))
                    return
                }
                ApiCallMetrics.record(operation: "get.cohorts", sample: sample, response: response)
                do {
                    let userCohorts = try self.handleResponse(response: response)
                    completion(.success(userCohorts))
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

class IdentifierDto: Codable {
    var type: String
    var value: String
}

class UserCohortDto: Codable {
    var identifier: IdentifierDto
    var cohorts: [Int64]
}

class UserCohortsResponseDto: Codable {
    var cohorts: [UserCohortDto]
}
