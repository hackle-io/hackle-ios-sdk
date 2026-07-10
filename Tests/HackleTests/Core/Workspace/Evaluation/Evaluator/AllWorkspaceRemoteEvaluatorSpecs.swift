import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class AllWorkspaceRemoteEvaluatorSpecs: AsyncSpec {
    override class func spec() {

        func evaluationDto() -> WorkspaceEvaluationDto {
            let file = Bundle(for: AllWorkspaceRemoteEvaluatorSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            return try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).evaluation!
        }

        func context() -> WorkspaceEvaluateContext {
            WorkspaceEvaluateContext.of(user: HackleUser.builder().identifier(.id, "id_1").build())
        }

        func record() -> WorkspaceEvaluationContext {
            WorkspaceEvaluationContext.of(key: context().key, dto: evaluationDto())
        }

        // 응답 JSON을 만들어 반환하는 헬퍼: status/evaluation/deleted를 dict로 조립 후 직렬화
        func responseData(status: String, evaluation: WorkspaceEvaluationDto?, deleted: [[String: Any]] = []) -> Data {
            // evaluation은 Codable이므로 encode 후 dict로 변환해 합성
            var body: [String: Any] = ["status": status, "deleted": deleted]
            if let evaluation = evaluation {
                let data = try! JSONEncoder().encode(evaluation)
                body["evaluation"] = try! JSONSerialization.jsonObject(with: data)
            }
            return try! JSONSerialization.data(withJSONObject: body)
        }

        var httpClient: MockHttpClient!
        var sut: AllWorkspaceRemoteEvaluator!
        var capturedBodies: [[String: Any]] = []

        beforeEach {
            httpClient = MockHttpClient()
            capturedBodies = []
            let client = WorkspaceRemoteEvaluateClient(sdkUrl: URL(string: "https://sdk-api.hackle.io")!, httpClient: httpClient)
            sut = AllWorkspaceRemoteEvaluator(client: client)
        }

        func stub(responses: [Data]) {
            var index = 0
            every(httpClient.executeMock).answers { request, completion in
                capturedBodies.append(try! JSONSerialization.jsonObject(with: request.body!) as! [String: Any])
                let data = responses[min(index, responses.count - 1)]
                index += 1
                completion(HttpResponse(
                    request: request,
                    data: data,
                    urlResponse: HTTPURLResponse(url: request.url, statusCode: 200, httpVersion: nil, headerFields: nil),
                    error: nil
                ))
            }
        }

        it("supports는 ALL scope만 true다") {
            expect(sut.supports(scope: .all)) == true
            expect(sut.supports(scope: .specific)) == false
        }

        it("record가 없으면 FORCE_FULL(빈 entities, current 없음)로 요청한다") {
            stub(responses: [responseData(status: "FULL", evaluation: evaluationDto())])

            let request = AllWorkspaceEvaluateRequest(context: context(), record: nil)
            let response = try await sut.evaluate(request: request)

            expect(capturedBodies[0]["policy"] as? String) == "FORCE_FULL"
            expect((capturedBodies[0]["entities"] as? [[String: Any]])?.count) == 0
            expect(capturedBodies[0]["current"]).to(beNil())
            expect(response.status) == WorkspaceEvaluateStatus.full
            expect(response.evaluation).toNot(beNil())
        }

        it("record가 있으면 AUTO(record의 type/id/hash entities + current metadata)로 요청한다") {
            stub(responses: [responseData(status: "NOT_MODIFIED", evaluation: nil)])

            let currentRecord = record()
            let request = AllWorkspaceEvaluateRequest(context: context(), record: currentRecord)
            let response = try await sut.evaluate(request: request)

            expect(capturedBodies[0]["policy"] as? String) == "AUTO"
            let entities = capturedBodies[0]["entities"] as! [[String: Any]]
            expect(entities.count) == currentRecord.dto.results.count
            expect(capturedBodies[0]["current"]).toNot(beNil())
            expect(response.status) == WorkspaceEvaluateStatus.notModified
            expect(response.evaluation).to(beNil())
        }

        it("DELTA 응답은 병합 후 hash가 일치하면 FULL로 반환한다") {
            let currentRecord = record()
            // 병합 결과 = 기존 그대로(빈 delta) → hash도 기존 results로 계산해 metadata에 넣음
            let mergedHash = WorkspaceEvaluationMerger.hash(results: currentRecord.dto.results)
            let deltaEvaluation = WorkspaceEvaluationDto(
                workspace: currentRecord.dto.workspace,
                results: [],
                metadata: WorkspaceEvaluationMetadataDto(
                    evaluatedAt: 1720000001000,
                    results: WorkspaceEvaluateResultsMetadataDto(hash: mergedHash),
                    user: HackleUserMetadataDto(hash: 0),
                    config: WorkspaceConfigMetadataDto(modifiedAt: "delta_modified_at")
                )
            )
            stub(responses: [responseData(status: "DELTA", evaluation: deltaEvaluation)])

            let response = try await sut.evaluate(request: AllWorkspaceEvaluateRequest(context: context(), record: currentRecord))

            expect(capturedBodies.count) == 1 // 재요청 없음
            expect(response.status) == WorkspaceEvaluateStatus.full
            expect(response.evaluation?.metadata.config.modifiedAt) == "delta_modified_at"
            expect(response.evaluation?.results.count) == currentRecord.dto.results.count
        }

        it("DELTA 병합 후 hash가 불일치하면 FORCE_FULL로 재요청한다") {
            let currentRecord = record()
            let deltaEvaluation = WorkspaceEvaluationDto(
                workspace: currentRecord.dto.workspace,
                results: [],
                metadata: WorkspaceEvaluationMetadataDto(
                    evaluatedAt: 1720000001000,
                    results: WorkspaceEvaluateResultsMetadataDto(hash: -1), // 불일치 유도
                    user: HackleUserMetadataDto(hash: 0),
                    config: WorkspaceConfigMetadataDto(modifiedAt: "delta_modified_at")
                )
            )
            stub(responses: [
                responseData(status: "DELTA", evaluation: deltaEvaluation),
                responseData(status: "FULL", evaluation: evaluationDto())
            ])

            let response = try await sut.evaluate(request: AllWorkspaceEvaluateRequest(context: context(), record: currentRecord))

            expect(capturedBodies.count) == 2
            expect(capturedBodies[1]["policy"] as? String) == "FORCE_FULL"
            expect(response.status) == WorkspaceEvaluateStatus.full
        }

        it("알 수 없는 status면 throw한다") {
            stub(responses: [responseData(status: "UNKNOWN", evaluation: nil)])

            await expect {
                try await sut.evaluate(request: AllWorkspaceEvaluateRequest(context: context(), record: nil))
            }.to(throwError())
        }
    }
}
