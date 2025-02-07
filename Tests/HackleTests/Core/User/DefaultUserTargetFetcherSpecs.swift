//
//  DefaultUserTargetFetcherSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//

import Nimble
import Quick
@testable import Hackle
import Foundation

class DefaultUserTargetFetcherSpecs: QuickSpec {
    override func spec() {
        var httpClient: MockHttpClient!
        var sut: DefaultUserTargetFetcher!

        beforeEach {
            httpClient = MockHttpClient()
            sut = DefaultUserTargetFetcher(config: HackleConfig.DEFAULT, httpClient: httpClient)
        }

        it("when error on fetch then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 500, error: HackleError.error("fail")))
            }

            var actual: Result<UserTarget, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            expect(try actual.get()).to(throwError(HackleError.error("fail")))
        }

        it("when response is empty then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(HttpResponse(request: request, data: nil, urlResponse: nil, error: nil))
            }

            var actual: Result<UserTarget, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            expect(try actual.get()).to(throwError(HackleError.error("Response is empty")))
        }

        it("when failed to fetch then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 500))
            }

            var actual: Result<UserTarget, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            expect(try actual.get()).to(throwError(HackleError.error("Http status code: 500")))
        }

        it("when response body is empty then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 200))
            }

            var actual: Result<UserTarget, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            expect(try actual.get()).to(throwError(HackleError.error("Response body is empty")))
        }

        it("when response body is invalid then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 200, data: "INVALID".data(using: .utf8)))
            }

            var actual: Result<UserTarget, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            expect(try actual.get()).to(throwError(HackleError.error("Invalid format")))
        }

        it("success") {
            let json = try! String(contentsOfFile: Bundle(for: DefaultUserTargetFetcherSpecs.self).path(forResource: "workspace_target", ofType: "json")!)
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 200, data: json.data(using: .utf8)))
            }

            var actual: Result<UserTarget, Error>!
            sut.fetch(user: User.builder().id("42").build()) { result in
                actual = result
            }

            let target = try actual.get()
            expect(target.targetEvents.count) == 2
        }

        it("request header") {
            let json = try! String(contentsOfFile: Bundle(for: DefaultUserTargetFetcherSpecs.self).path(forResource: "workspace_target", ofType: "json")!)
            every(httpClient.executeMock).answers { request, completion in
                completion(response(statusCode: 200, data: json.data(using: .utf8)))
            }

            sut.fetch(user: User.builder().id("42").build()) { _ in }

            let request = httpClient.executeMock.firstInvokation().arguments.0
            expect(request.headers?["X-HACKLE-USER"]).toNot(beNil())
        }

        func response(statusCode: Int, data: Data? = nil, error: Error? = nil) -> HttpResponse {
            HttpResponse(
                request: HttpRequest.get(url: URL(string: "localhost")!),
                data: data,
                urlResponse: HTTPURLResponse(url: URL(string: "localhost")!, statusCode: statusCode, httpVersion: nil, headerFields: nil),
                error: error
            )
        }
    }
}
