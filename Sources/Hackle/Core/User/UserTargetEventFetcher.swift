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
    private let timeout: TimeInterval = 10 // watchdog mainthread crash 회피를 위해 10초 설정

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
    var events: [TargetEventDto]
}

class TargetEventDto: Codable {
    /// 타겟팅 할 이벤트
    let eventKey: String
    /// 이벤트 통계
    let stats: [StatDto]
    /// 타겟팅에 추가로 이용 할 이벤트 프로퍼티
    let property: PropertyDto?
}

class StatDto: Codable {
    let date: Int64
    let count: Int
}

class PropertyDto: Codable {
    /// 키
    let key: String
    /// 타입
    ///
    /// 현재는 EVENT_PROPERTY만 지원
    let type: Target.KeyType
    /// 값
    let value: HackleValue
}

class MatchDto: Codable {
    
}
