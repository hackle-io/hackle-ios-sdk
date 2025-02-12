//
//  DefaultHttpWorkspaceFetcherSpecs.swift
//  HackleTests
//
//  Created by yong on 2023/10/02.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultHttpWorkspaceFetcherSpecs: QuickSpec {

    override func spec() {

        var httpClient: MockHttpClient!

        beforeEach {
            httpClient = MockHttpClient()
        }

        func response(request: HttpRequest, statusCode: Int? = nil, data: Data? = nil, headers: [String: String] = [:], error: Error? = nil) -> HttpResponse {
            var urlResponse: HTTPURLResponse? = nil
            if let statusCode {
                urlResponse = HTTPURLResponse(url: request.url, statusCode: statusCode, httpVersion: nil, headerFields: headers)
            }
            return HttpResponse(request: request, data: data, urlResponse: urlResponse, error: error)
        }

        func sdk(key: String) -> Sdk {
            Sdk(key: key, name: "test-sdk", version: "test-version")
        }

        it("when error on http call then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(request: request, error: HackleError.error("fail")))
            }
            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "test-key"), httpClient: httpClient)

            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            expect(try actual.get()).to(throwError(HackleError.error("fail")))
        }

        it("when url response is empty then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(request: request))
            }
            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "test-key"), httpClient: httpClient)

            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            expect(try actual.get()).to(throwError(HackleError.error("Response is empty")))
        }

        it("when workspace config is not modified then complete with nil") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(request: request, statusCode: 304))
            }
            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "test-key"), httpClient: httpClient)

            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified(lastModified: "LAST_MODIFIED_HEADER_VALUE") { result in
                actual = result
            }
            expect(try actual.get()).to(beNil())
        }

        it("when http call is not successful then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(request: request, statusCode: 500))
            }
            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "test-key"), httpClient: httpClient)

            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            expect(try actual.get()).to(throwError(HackleError.error("Http status code: 500")))
        }

        it("when response body is empty then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(request: request, statusCode: 200, data: nil))
            }
            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "test-key"), httpClient: httpClient)

            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            expect(try actual.get()).to(throwError(HackleError.error("Response body is empty")))
        }

        it("when response body is invalid format then complete with error") {
            every(httpClient.executeMock).answers { request, completion in
                completion(response(request: request, statusCode: 200, data: "INVALID".data(using: .utf8)))
            }
            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "test-key"), httpClient: httpClient)

            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            expect(try actual.get()).to(throwError(HackleError.error("Invalid format")))
        }

        it("when success to get workspace then complete with workspace config dto") {
            let json = try! String(contentsOfFile: Bundle(for: DefaultHttpWorkspaceFetcherSpecs.self).path(forResource: "workspace_response", ofType: "json")!)
            every(httpClient.executeMock).answers { request, completion in
                completion(response(request: request, statusCode: 200, data: json.data(using: .utf8)))
            }
            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "test-key"), httpClient: httpClient)

            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            expect(try actual.get()).toNot(beNil())
        }

        it("url") {
            let json = try! String(contentsOfFile: Bundle(for: DefaultHttpWorkspaceFetcherSpecs.self).path(forResource: "workspace_response", ofType: "json")!)
            every(httpClient.executeMock).answers { request, completion in
                completion(response(request: request, statusCode: 200, data: json.data(using: .utf8)))
            }
            let config = HackleConfig.builder()
                .sdkUrl(URL(string: "localhost")!)
                .build()
            let sut = DefaultHttpWorkspaceFetcher(config: config, sdk: sdk(key: "SDK_KEY"), httpClient: httpClient)

            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            expect(try actual.get()).toNot(beNil())

            expect(httpClient.executeMock.firstInvokation().arguments.0.url) == URL(string: "localhost/api/v2/workspaces/SDK_KEY/config")
        }

        it("last modified") {
            let json = try! String(contentsOfFile: Bundle(for: DefaultHttpWorkspaceFetcherSpecs.self).path(forResource: "workspace_response", ofType: "json")!)
            var isModified = true
            every(httpClient.executeMock).answers { request, completion in
                if isModified {
                    completion(response(request: request, statusCode: 200, data: json.data(using: .utf8), headers: ["Last-Modified": "LAST_MODIFIED_HEADER_VALUE"]))
                    isModified = false
                } else {
                    completion(response(request: request, statusCode: 304, data: nil))
                }
            }

            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "SDK_KEY"), httpClient: httpClient)
            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            expect(try actual.get()).toNot(beNil())
            sut.fetchIfModified(lastModified: "LAST_MODIFIED_HEADER_VALUE") { result in
                actual = result
            }
            Thread.sleep(forTimeInterval: 0.1)
            expect(try actual.get()).to(beNil())

            let invokes = httpClient.executeMock.invokations()
            expect(invokes[0].arguments.0.headers).to(beNil())
            expect(invokes[1].arguments.0.headers!["If-Modified-Since"]) == "LAST_MODIFIED_HEADER_VALUE"
        }
        
        it("result value contains last modified value") {
            let json = try! String(contentsOfFile: Bundle(for: DefaultHttpWorkspaceFetcherSpecs.self)
                .path(forResource: "workspace_response", ofType: "json")!)
            every(httpClient.executeMock)
                .answers { request, completion in
                    completion(response(request: request, statusCode: 200, data: json.data(using: .utf8), headers: ["Last-Modified": "LAST_MODIFIED_HEADER_VALUE"]))
                }
            
            let sut = DefaultHttpWorkspaceFetcher(config: HackleConfig.DEFAULT, sdk: sdk(key: "SDK_KEY"), httpClient: httpClient)
            var actual: Result<WorkspaceConfig?, Error>!
            sut.fetchIfModified { result in
                actual = result
            }
            
            let config = try actual.get()
            expect(config).toNot(beNil())
            expect(config?.lastModified) == "LAST_MODIFIED_HEADER_VALUE"
        }
    }
}

private class HttpClientStub: HttpClient {
    private let statusCode: Int?
    private let data: Data?
    private let error: Error?

    init(statusCode: Int? = nil, data: Data? = nil, error: Error? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.error = error
    }

    func execute(request: HttpRequest, completion: @escaping (HttpResponse) -> ()) {
        var urlResponse: HTTPURLResponse? = nil
        if let statusCode {
            urlResponse = HTTPURLResponse(url: request.url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
        }
        let response = HttpResponse(request: request, data: data, urlResponse: urlResponse, error: error)
        completion(response)
    }
    
    func execute(request: HttpRequest, timeout: TimeInterval, completion: @escaping (HttpResponse) -> Void) {
        execute(request: request, completion: completion)
    }
}
