import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class WorkspaceRemoteEvaluateClientSpecs: AsyncSpec {
    override class func spec() {

        func requestDto() -> WorkspaceEvaluateRequestDto {
            WorkspaceEvaluateRequestDto(
                scope: "ALL",
                policy: "FORCE_FULL",
                context: WorkspaceEvaluateContextDto(
                    platformType: "IOS",
                    user: HackleUserDto(identifiers: ["$id": "id_1"], userProperties: ["age": 30], hackleProperties: [:]),
                    operations: ["$set": ["grade": "GOLD"]]
                ),
                entities: [EvaluateEntityDto(type: "AB_TEST", id: 1, hash: 10), EvaluateEntityDto(type: "AB_TEST", id: 2, hash: nil)],
                current: nil
            )
        }

        func successBody() -> Data {
            let file = Bundle(for: WorkspaceRemoteEvaluateClientSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            return try! Data(contentsOf: URL(fileURLWithPath: file))
        }

        func httpResponse(request: HttpRequest, statusCode: Int, data: Data?) -> HttpResponse {
            HttpResponse(
                request: request,
                data: data,
                urlResponse: HTTPURLResponse(url: request.url, statusCode: statusCode, httpVersion: nil, headerFields: nil),
                error: nil
            )
        }

        var httpClient: MockHttpClient!
        var sut: WorkspaceRemoteEvaluateClient!
        var capturedRequest: HttpRequest?

        beforeEach {
            httpClient = MockHttpClient()
            capturedRequest = nil
            sut = WorkspaceRemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
        }

        func stub(statusCode: Int, data: Data?) {
            every(httpClient.executeMock).answers { request, completion in
                capturedRequest = request
                completion(httpResponse(request: request, statusCode: statusCode, data: data))
            }
        }

        it("POST {sdkUrl}/api/v1/evaluate 로 요청 body를 직렬화해 보낸다") {
            stub(statusCode: 200, data: successBody())

            _ = try await sut.evaluate(request: requestDto())

            expect(capturedRequest?.url.absoluteString) == "https://sdk-api.hackle.io/api/v1/evaluate"
            expect(capturedRequest?.method.lowercased()) == "post"

            let body = try! JSONSerialization.jsonObject(with: capturedRequest!.body!) as! [String: Any]
            expect(body["scope"] as? String) == "ALL"
            expect(body["policy"] as? String) == "FORCE_FULL"
            expect(body["current"]).to(beNil())
            let context = body["context"] as! [String: Any]
            expect(context["platformType"] as? String) == "IOS"
            let user = context["user"] as! [String: Any]
            expect(user["identifiers"] as? [String: String]) == ["$id": "id_1"]
            let entities = body["entities"] as! [[String: Any]]
            expect(entities.count) == 2
            expect(entities[0]["hash"] as? Int) == 10
            expect(entities[1]["hash"]).to(beNil()) // hash nil은 키 생략
        }

        it("2xx 응답 body를 WorkspaceEvaluateResponseDto로 디코딩한다") {
            stub(statusCode: 200, data: successBody())

            let response = try await sut.evaluate(request: requestDto())

            expect(response.status) == "FULL"
            expect(response.evaluation).toNot(beNil())
        }

        it("2xx가 아니면 throw한다") {
            stub(statusCode: 500, data: nil)

            await expect { try await sut.evaluate(request: requestDto()) }.to(throwError())
        }

        it("body가 없으면 throw한다") {
            stub(statusCode: 200, data: nil)

            await expect { try await sut.evaluate(request: requestDto()) }.to(throwError())
        }

        it("body 파싱에 실패하면 throw한다") {
            stub(statusCode: 200, data: "broken".data(using: .utf8)!)

            await expect { try await sut.evaluate(request: requestDto()) }.to(throwError())
        }

        it("deleted·evaluation이 생략된 NOT_MODIFIED 응답을 디코딩한다") {
            stub(statusCode: 200, data: #"{"status":"NOT_MODIFIED"}"#.data(using: .utf8)!)

            let response = try await sut.evaluate(request: requestDto())

            expect(response.status) == "NOT_MODIFIED"
            expect(response.evaluation).to(beNil())
            expect(response.deleted).to(beEmpty())
        }
    }
}
