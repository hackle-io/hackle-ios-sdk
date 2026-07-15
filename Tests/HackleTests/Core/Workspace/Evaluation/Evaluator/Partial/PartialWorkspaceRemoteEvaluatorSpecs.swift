import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class PartialWorkspaceRemoteEvaluatorSpecs: AsyncSpec {
    override class func spec() {

        func context() -> RemoteEvaluateContext {
            RemoteEvaluateContext.of(user: HackleUser.builder().identifier(.id, "id_1").build())
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

        it("entity-evaluate 엔드포인트로 entities를 직렬화해 보낸다") {
            let httpClient = MockHttpClient()
            let sut = PartialWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            var capturedRequest: HttpRequest?
            every(httpClient.executeMock).answers { request, completion in
                capturedRequest = request
                completion(httpResponse(request: request, statusCode: 200, data: entityResponseBody()))
            }

            let request = PartialWorkspaceEvaluateRequest(
                context: context(),
                entities: [DefaultEntity(serviceType: .inAppMessage, id: 400)]
            )
            _ = try await sut.evaluate(request: request)

            expect(capturedRequest?.url.absoluteString) == "https://sdk-api.hackle.io/api/v1/entity-evaluate"
            let body = try! JSONSerialization.jsonObject(with: capturedRequest!.body!) as! [String: Any]
            let entities = body["entities"] as! [[String: Any]]
            expect(entities.count) == 1
            expect(entities[0]["type"] as? String) == "IN_APP_MESSAGE"
            expect(entities[0]["id"] as? Int) == 400
        }

        it("응답 evaluation을 DefaultWorkspaceEvaluation으로 변환한다 (fullEvaluatedAt 없음)") {
            let httpClient = MockHttpClient()
            let sut = PartialWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 200, data: entityResponseBody()))
            }

            let request = PartialWorkspaceEvaluateRequest(
                context: context(),
                entities: [DefaultEntity(serviceType: .inAppMessage, id: 400)]
            )
            let response = try await sut.evaluate(request: request)

            expect(response.evaluation.metadata.id) == 1
            expect(response.evaluation.evaluatedAt) == 1720000000000
            expect(response.evaluation.toProperties()["remote_full_evaluated_at"]).to(beNil())
        }

        it("2xx가 아니면 throw한다") {
            let httpClient = MockHttpClient()
            let sut = PartialWorkspaceRemoteEvaluator(client: RemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient))
            every(httpClient.executeMock).answers { request, completion in
                completion(httpResponse(request: request, statusCode: 500, data: nil))
            }

            let request = PartialWorkspaceEvaluateRequest(context: context(), entities: [])
            await expect { try await sut.evaluate(request: request) }.to(throwError())
        }
    }
}
