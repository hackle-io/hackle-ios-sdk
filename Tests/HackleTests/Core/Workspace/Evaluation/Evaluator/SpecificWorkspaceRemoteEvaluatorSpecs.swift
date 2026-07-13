import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class SpecificWorkspaceRemoteEvaluatorSpecs: AsyncSpec {
    override class func spec() {

        func evaluationData() -> Data {
            let file = Bundle(for: SpecificWorkspaceRemoteEvaluatorSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            return try! Data(contentsOf: URL(fileURLWithPath: file))
        }

        var httpClient: MockHttpClient!
        var sut: SpecificWorkspaceRemoteEvaluator!
        var capturedBody: [String: Any]?

        beforeEach {
            httpClient = MockHttpClient()
            capturedBody = nil
            let client = WorkspaceRemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            sut = SpecificWorkspaceRemoteEvaluator(client: client)
            every(httpClient.executeMock).answers { request, completion in
                capturedBody = try! JSONSerialization.jsonObject(with: request.body!) as? [String: Any]
                completion(HttpResponse(
                    request: request,
                    data: evaluationData(),
                    urlResponse: HTTPURLResponse(url: request.url, statusCode: 200, httpVersion: nil, headerFields: nil),
                    error: nil
                ))
            }
        }

        it("supports는 SPECIFIC scope만 true다") {
            expect(sut.supports(scope: .specific)) == true
            expect(sut.supports(scope: .all)) == false
        }

        it("항상 FORCE_FULL + targets의 serviceType/id(hash 없음)로 요청하고 응답을 FULL로 취급한다") {
            let user = HackleUser.builder().identifier(.id, "id_1").build()
            let request = SpecificWorkspaceEvaluateRequest(
                context: WorkspaceEvaluateContext.of(user: user),
                targets: [DefaultEntity(serviceType: .inAppMessage, id: 400)]
            )

            let response = try await sut.evaluate(request: request)

            expect(capturedBody?["scope"] as? String) == "SPECIFIC"
            expect(capturedBody?["policy"] as? String) == "FORCE_FULL"
            let entities = capturedBody?["entities"] as! [[String: Any]]
            expect(entities.count) == 1
            expect(entities[0]["type"] as? String) == "IN_APP_MESSAGE"
            expect(entities[0]["id"] as? Int) == 400
            expect(entities[0]["hash"]).to(beNil())
            expect(capturedBody?["current"]).to(beNil())

            expect(response.status) == WorkspaceEvaluateStatus.full
            expect(response.evaluation).toNot(beNil())
        }

        it("지원하지 않는 request 타입이면 throw한다") {
            let user = HackleUser.builder().identifier(.id, "id_1").build()
            let request = AllWorkspaceEvaluateRequest(context: WorkspaceEvaluateContext.of(user: user), record: nil)

            await expect {
                try await sut.evaluate(request: request)
            }.to(throwError())
        }
    }
}
