import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class FullWorkspaceRemoteEvaluatorSpecs: AsyncSpec {
    override class func spec() {

        func evaluationDto() -> WorkspaceEvaluationDto {
            let file = Bundle(for: FullWorkspaceRemoteEvaluatorSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            return try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).full!
        }

        func context() -> RemoteEvaluateContext {
            RemoteEvaluateContext.of(user: HackleUser.builder().identifier(.id, "id_1").build())
        }

        func base() -> WorkspaceEvaluationContext {
            WorkspaceEvaluationContext.of(key: context().key, dto: evaluationDto(), fullEvaluatedAt: 999)
        }

        // 응답 JSON을 만들어 반환: status/full/delta를 dict로 조립 후 직렬화
        func responseData(status: String, full: WorkspaceEvaluationDto? = nil, delta: [String: Any]? = nil) -> Data {
            var body: [String: Any] = ["status": status]
            if let full = full {
                let data = try! JSONEncoder().encode(full)
                body["full"] = try! JSONSerialization.jsonObject(with: data)
            }
            if let delta = delta {
                body["delta"] = delta
            }
            return try! JSONSerialization.data(withJSONObject: body)
        }

        func deltaDict(hash: Int32, changed: [[String: Any]] = [], deleted: [[String: Any]] = []) -> [String: Any] {
            [
                "metadata": [
                    "hash": Int(hash),
                    "evaluatedAt": 1720000001000,
                    "user": ["hash": 0],
                    "config": ["modifiedAt": "delta_modified_at"]
                ],
                "changed": changed,
                "deleted": deleted
            ]
        }

        func httpResponse(request: HttpRequest, statusCode: Int, data: Data?) -> HttpResponse {
            HttpResponse(
                request: request,
                data: data,
                urlResponse: HTTPURLResponse(url: request.url, statusCode: statusCode, httpVersion: nil, headerFields: nil),
                error: nil
            )
        }

        it("base가 없으면 FORCE_FULL(base 없음)로 요청한다") {
            let httpClient = MockHttpClient()
            let sut = FullWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            var capturedBodies: [[String: Any]] = []
            every(httpClient.executeMock).answers { request, completion in
                capturedBodies.append(try! JSONSerialization.jsonObject(with: request.body!) as! [String: Any])
                completion(httpResponse(request: request, statusCode: 200, data: responseData(status: "FULL", full: evaluationDto())))
            }

            let request = FullWorkspaceEvaluateRequest.of(context: context(), base: nil)
            let response = try await sut.evaluate(request: request)

            expect(capturedBodies[0]["policy"] as? String) == "FORCE_FULL"
            expect(capturedBodies[0]["base"]).to(beNil())
            expect(response.evaluation.metadata.id) == 1
        }

        it("base가 있으면 AUTO(base의 entities + metadata)로 요청한다") {
            let httpClient = MockHttpClient()
            let sut = FullWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            let currentBase = base()
            var capturedBodies: [[String: Any]] = []
            every(httpClient.executeMock).answers { request, completion in
                capturedBodies.append(try! JSONSerialization.jsonObject(with: request.body!) as! [String: Any])
                completion(httpResponse(request: request, statusCode: 204, data: nil))
            }

            let request = FullWorkspaceEvaluateRequest.of(context: context(), base: currentBase)
            _ = try await sut.evaluate(request: request)

            expect(capturedBodies[0]["policy"] as? String) == "AUTO"
            let baseBody = capturedBodies[0]["base"] as! [String: Any]
            let entities = baseBody["entities"] as! [[String: Any]]
            expect(entities.count) == currentBase.dto.results.count
        }

        it("204(NOT_MODIFIED) 응답이면 base의 context를 그대로 반환한다") {
            let httpClient = MockHttpClient()
            let sut = FullWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 204, data: nil))
            }

            let request = FullWorkspaceEvaluateRequest.of(context: context(), base: base())
            let response = try await sut.evaluate(request: request)

            expect(response.context.fullEvaluatedAt) == 999
        }

        it("204인데 base가 없으면 throw한다") {
            let httpClient = MockHttpClient()
            let sut = FullWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 204, data: nil))
            }

            let request = FullWorkspaceEvaluateRequest.of(context: context(), base: nil)
            await expect { try await sut.evaluate(request: request) }.to(throwError())
        }

        it("FULL 응답이면 새 context를 만들고 fullEvaluatedAt은 full.metadata.evaluatedAt이다") {
            let httpClient = MockHttpClient()
            let sut = FullWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 200, data: responseData(status: "FULL", full: evaluationDto())))
            }

            let request = FullWorkspaceEvaluateRequest.of(context: context(), base: base())
            let response = try await sut.evaluate(request: request)

            expect(response.context.fullEvaluatedAt) == 1720000000000 // full.metadata.evaluatedAt
        }

        it("DELTA 응답은 병합 후 hash가 일치하면 재요청 없이 병합 결과를 반환하고 fullEvaluatedAt을 보존한다") {
            let httpClient = MockHttpClient()
            let sut = FullWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            let currentBase = base()
            let mergedHash = WorkspaceEvaluationMerger.hash(results: currentBase.dto.results)
            var capturedBodies: [[String: Any]] = []
            every(httpClient.executeMock).answers { request, completion in
                capturedBodies.append(try! JSONSerialization.jsonObject(with: request.body!) as! [String: Any])
                completion(httpResponse(request: request, statusCode: 200, data: responseData(status: "DELTA", delta: deltaDict(hash: mergedHash))))
            }

            let request = FullWorkspaceEvaluateRequest.of(context: context(), base: currentBase)
            let response = try await sut.evaluate(request: request)

            expect(capturedBodies.count) == 1 // 재요청 없음
            expect(response.context.fullEvaluatedAt) == 999 // base의 fullEvaluatedAt 보존
            expect(response.evaluation.modifiedAt) == "delta_modified_at"
        }

        it("DELTA 병합 후 hash가 불일치하면 FORCE_FULL로 재요청한다") {
            let httpClient = MockHttpClient()
            let sut = FullWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            var capturedBodies: [[String: Any]] = []
            var index = 0
            let responses = [
                responseData(status: "DELTA", delta: deltaDict(hash: -1)),
                responseData(status: "FULL", full: evaluationDto())
            ]
            every(httpClient.executeMock).answers { request, completion in
                capturedBodies.append(try! JSONSerialization.jsonObject(with: request.body!) as! [String: Any])
                let data = responses[min(index, responses.count - 1)]
                index += 1
                completion(httpResponse(request: request, statusCode: 200, data: data))
            }

            let request = FullWorkspaceEvaluateRequest.of(context: context(), base: base())
            let response = try await sut.evaluate(request: request)

            expect(capturedBodies.count) == 2
            expect(capturedBodies[1]["policy"] as? String) == "FORCE_FULL"
            expect(capturedBodies[1]["base"]).to(beNil())
            expect(response.context.fullEvaluatedAt) == 1720000000000
        }

        it("알 수 없는 status면 throw한다") {
            let httpClient = MockHttpClient()
            let sut = FullWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 200, data: responseData(status: "UNKNOWN")))
            }

            let request = FullWorkspaceEvaluateRequest.of(context: context(), base: base())
            await expect { try await sut.evaluate(request: request) }.to(throwError())
        }
    }
}
