import Foundation
import Nimble
import Quick
@testable import Hackle


class DefaultUserCohortFetcherSpecs: QuickSpec {
    override func spec() {
        var httpClient: MockHttpClient!
        var sut: DefaultUserCohortFetcher!


        beforeEach {
            httpClient = MockHttpClient()
            sut = DefaultUserCohortFetcher(config: HackleConfig.DEFAULT, httpClient: httpClient)
        }

        it("when error on fetch then complete with error") {
            // given
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 500, error: HackleError.error("fail")))
            }

            // when
            var actual: Result<UserCohorts, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            // then
            expect(try actual.get()).to(throwError(HackleError.error("fail")))
        }

        it("when response is empty then complete with error") {
            // given
            every(httpClient.executeMock).answers { request, completion in
                completion(HttpResponse(request: request, data: nil, urlResponse: nil, error: nil))
            }

            // when
            var actual: Result<UserCohorts, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            // then
            expect(try actual.get()).to(throwError(HackleError.error("Response is empty")))
        }

        it("when failed to fetch then complete with error") {
            // given
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 500))
            }

            // when
            var actual: Result<UserCohorts, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            // then
            expect(try actual.get()).to(throwError(HackleError.error("Http status code: 500")))
        }

        it("when response body is empty then complete with error") {
            // given
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 200))
            }

            // when
            var actual: Result<UserCohorts, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            // then
            expect(try actual.get()).to(throwError(HackleError.error("Response body is empty")))
        }

        it("when response body is invalid then complete with error") {
            // given
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 200, data: "INVALID".data(using: .utf8)))
            }

            // when
            var actual: Result<UserCohorts, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            // then
            expect(try actual.get()).to(throwError(HackleError.error("Invalid format")))
        }

        it("success") {
            // given
            let json = try! String(contentsOfFile: Bundle(for: DefaultUserCohortFetcherSpecs.self).path(forResource: "workspace_cohorts", ofType: "json")!)
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 200, data: json.data(using: .utf8)))
            }

            // when
            var actual: Result<UserCohorts, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            // then
            let cohorts = try actual.get()
            expect(cohorts.count) == 2
            expect(cohorts.rawCohorts) == [Cohort(id: 1), Cohort(id: 2)]
            expect(cohorts[Identifier(type: "$id", value: "id")]) == UserCohort(identifier: Identifier(type: "$id", value: "id"), cohorts: [Cohort(id: 1), Cohort(id: 2)])
            expect(cohorts[Identifier(type: "$userId", value: "user_id")]) == UserCohort(identifier: Identifier(type: "$userId", value: "user_id"), cohorts: [])
        }

        it("request header") {
            // given
            let json = try! String(contentsOfFile: Bundle(for: DefaultUserCohortFetcherSpecs.self).path(forResource: "workspace_cohorts", ofType: "json")!)
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 200, data: json.data(using: .utf8)))
            }

            // when
            sut.fetch(user: User.builder().id("42").build()) { result in
            }

            // then
            let request = httpClient.executeMock.firstInvokation().arguments.0
            expect(request.headers?["X-HACKLE-USER"]).toNot(beNil())
        }

        func response(statusCode: Int, data: Data? = nil, error: Error? = nil) -> HttpResponse {
            let url = URL(string: "localhost")!

            return HttpResponse(
                request: HttpRequest.get(url: URL(string: "localhost")!),
                data: data,
                urlResponse: HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil),
                error: error)
        }
    }
}