import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class RemoteEvaluateClientSpecs: AsyncSpec {
    override class func spec() {

        func requestDto() -> WorkspaceEvaluateRequestDto {
            WorkspaceEvaluateRequestDto(
                policy: "AUTO",
                context: RemoteEvaluateContextDto(
                    user: HackleUserDto(identifiers: ["$id": "id_1"], userProperties: ["age": 30], hackleProperties: [:]),
                    operations: ["$set": ["grade": "GOLD"]]
                ),
                base: BaseEvaluationDto(
                    fullEvaluatedAt: 1720000000000,
                    metadata: WorkspaceEvaluationMetadataDto(
                        hash: 12345,
                        evaluatedAt: 1720000000000,
                        user: HackleUserMetadataDto(hash: 67890),
                        config: WorkspaceConfigMetadataDto(modifiedAt: "modified_at")
                    ),
                    entities: [EvaluateEntityDto(type: "AB_TEST", id: 1, hash: 10)]
                )
            )
        }

        func entityRequestDto() -> EntityEvaluateRequestDto {
            EntityEvaluateRequestDto(
                context: RemoteEvaluateContextDto(
                    user: HackleUserDto(identifiers: ["$id": "id_1"], userProperties: [:], hackleProperties: [:]),
                    operations: [:]
                ),
                entities: [EntityDto(type: "IN_APP_MESSAGE", id: 400)]
            )
        }

        func successBody() -> Data {
            let file = Bundle(for: RemoteEvaluateClientSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            return try! Data(contentsOf: URL(fileURLWithPath: file))
        }

        func entityResponseBody() -> Data {
            let json = """
            {
              "evaluation": {
                "workspace": {"id": 1, "environment": {"id": 2}},
                "metadata": {
                  "evaluatedAt": 1720000000000,
                  "config": {"modifiedAt": "Thu, 10 Jul 2026 00:00:00 GMT"}
                },
                "results": []
              }
            }
            """
            return json.data(using: .utf8)!
        }

        func httpResponse(request: HttpRequest, statusCode: Int, data: Data?) -> HttpResponse {
            HttpResponse(
                request: request,
                data: data,
                urlResponse: HTTPURLResponse(url: request.url, statusCode: statusCode, httpVersion: nil, headerFields: nil),
                error: nil
            )
        }

        it("POST {sdkUrl}/api/v1/workspace-evaluate 로 요청 body를 직렬화해 보낸다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            var capturedRequest: HttpRequest?
            every(httpClient.executeMock).answers { request, completion in
                capturedRequest = request
                completion(httpResponse(request: request, statusCode: 200, data: successBody()))
            }

            _ = try await sut.evaluateIfModified(request: requestDto())

            expect(capturedRequest?.url.absoluteString) == "https://sdk-api.hackle.io/api/v1/workspace-evaluate"
            expect(capturedRequest?.method.lowercased()) == "post"

            let body = try! JSONSerialization.jsonObject(with: capturedRequest!.body!) as! [String: Any]
            expect(body["policy"] as? String) == "AUTO"
            let context = body["context"] as! [String: Any]
            expect(context["operations"] as? [String: [String: String]]) == ["$set": ["grade": "GOLD"]]
            let base = body["base"] as! [String: Any]
            expect(base["fullEvaluatedAt"] as? Int64) == 1720000000000
            let metadata = base["metadata"] as! [String: Any]
            expect(metadata["hash"] as? Int) == 12345
            let entities = base["entities"] as! [[String: Any]]
            expect(entities.count) == 1
            expect(entities[0]["hash"] as? Int) == 10
        }

        it("workspace-evaluate 204 응답이면 nil을 반환한다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 204, data: nil))
            }

            let response = try await sut.evaluateIfModified(request: requestDto())

            expect(response).to(beNil())
        }

        it("workspace-evaluate 2xx 응답 body를 신 포맷으로 디코딩한다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 200, data: successBody()))
            }

            let response = try await sut.evaluateIfModified(request: requestDto())

            expect(response?.status) == "FULL"
            expect(response?.full).toNot(beNil())
            expect(response?.delta).to(beNil())
        }

        it("POST {sdkUrl}/api/v1/entity-evaluate 로 entities를 보낸다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            var capturedRequest: HttpRequest?
            every(httpClient.executeMock).answers { request, completion in
                capturedRequest = request
                completion(httpResponse(request: request, statusCode: 200, data: entityResponseBody()))
            }

            let response = try await sut.evaluateEntities(request: entityRequestDto())

            expect(capturedRequest?.url.absoluteString) == "https://sdk-api.hackle.io/api/v1/entity-evaluate"
            expect(capturedRequest?.method.lowercased()) == "post"
            let body = try! JSONSerialization.jsonObject(with: capturedRequest!.body!) as! [String: Any]
            let entities = body["entities"] as! [[String: Any]]
            expect(entities.count) == 1
            expect(entities[0]["type"] as? String) == "IN_APP_MESSAGE"
            expect(entities[0]["id"] as? Int) == 400
            expect(response.evaluation.workspace.id) == 1
        }

        it("2xx가 아니면 throw한다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 500, data: nil))
            }

            await expect { try await sut.evaluateIfModified(request: requestDto()) }.to(throwError())
        }

        it("네트워크 오류(response.error)면 workspace-evaluate가 해당 에러를 그대로 throw한다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            every(httpClient.executeMock).answers { request, completion in
                completion(HttpResponse(request: request, data: nil, urlResponse: nil, error: URLError(.timedOut)))
            }

            await expect { try await sut.evaluateIfModified(request: requestDto()) }.to(throwError(URLError(.timedOut)))
        }

        it("네트워크 오류(response.error)면 entity-evaluate가 해당 에러를 그대로 throw한다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            every(httpClient.executeMock).answers { request, completion in
                completion(HttpResponse(request: request, data: nil, urlResponse: nil, error: URLError(.timedOut)))
            }

            await expect { try await sut.evaluateEntities(request: entityRequestDto()) }.to(throwError(URLError(.timedOut)))
        }

        it("body가 없으면 throw한다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 200, data: nil))
            }

            await expect { try await sut.evaluateIfModified(request: requestDto()) }.to(throwError())
        }

        it("원격 평가 요청에 10초 타임아웃을 지정한다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 200, data: successBody()))
            }
            _ = try await sut.evaluateIfModified(request: requestDto())

            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 200, data: entityResponseBody()))
            }
            _ = try await sut.evaluateEntities(request: entityRequestDto())

            expect(httpClient.capturedTimeouts) == [10, 10]
        }

        it("body 파싱에 실패하면 throw한다") {
            let httpClient = MockHttpClient()
            let sut = RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 200, data: "broken".data(using: .utf8)!))
            }

            await expect { try await sut.evaluateIfModified(request: requestDto()) }.to(throwError())
        }
    }
}
