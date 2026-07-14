import Foundation
import Quick
import Nimble
@testable import Hackle

class WorkspaceEvaluationMergerSpecs: QuickSpec {
    override class func spec() {

        func workspaceDto() -> WorkspaceDto {
            let json = #"{"id": 1, "environment": {"id": 2}}"#
            return try! JSONDecoder().decode(WorkspaceDto.self, from: json.data(using: .utf8)!)
        }

        func result(type: String = "AB_TEST", id: Int64, hash: Int32) -> EvaluateResultDto {
            EvaluateResultDto(type: type, id: id, hash: hash, experiment: nil, featureFlag: nil, remoteConfig: nil, inAppMessage: nil)
        }

        func metadata(resultsHash: Int32 = 0) -> WorkspaceEvaluationMetadataDto {
            WorkspaceEvaluationMetadataDto(
                evaluatedAt: 1720000000000,
                results: WorkspaceEvaluateResultsMetadataDto(hash: resultsHash),
                user: HackleUserMetadataDto(hash: 0),
                config: WorkspaceConfigMetadataDto(modifiedAt: "modified_at")
            )
        }

        func evaluation(results: [EvaluateResultDto], metadata m: WorkspaceEvaluationMetadataDto? = nil) -> WorkspaceEvaluationDto {
            WorkspaceEvaluationDto(workspace: workspaceDto(), results: results, metadata: m ?? metadata())
        }

        describe("merge") {
            it("같은 (type,id)는 응답으로 교체하고 새 항목은 뒤에 추가하며 순서를 보존한다") {
                let current = evaluation(results: [
                    result(id: 1, hash: 10),
                    result(id: 2, hash: 20),
                    result(id: 3, hash: 30)
                ])
                let responseMetadata = metadata(resultsHash: 999)
                let response = WorkspaceEvaluateResponseDto(
                    status: "DELTA",
                    evaluation: evaluation(results: [
                        result(id: 2, hash: 21),
                        result(id: 4, hash: 40)
                    ], metadata: responseMetadata),
                    deleted: []
                )

                let merged = try! WorkspaceEvaluationMerger.merge(evaluation: current, response: response)

                expect(merged.results.map { $0.id }) == [1, 2, 3, 4]
                expect(merged.results.map { $0.hash }) == [10, 21, 30, 40]
                expect(merged.metadata.results.hash) == 999 // metadata는 응답 것
                expect(merged.workspace.id) == 1 // workspace는 기존 것
            }

            it("type이 다르면 id가 같아도 다른 항목이다") {
                let current = evaluation(results: [result(type: "AB_TEST", id: 1, hash: 10)])
                let response = WorkspaceEvaluateResponseDto(
                    status: "DELTA",
                    evaluation: evaluation(results: [result(type: "FEATURE_FLAG", id: 1, hash: 11)]),
                    deleted: []
                )

                let merged = try! WorkspaceEvaluationMerger.merge(evaluation: current, response: response)

                expect(merged.results.count) == 2
            }

            it("deleted 항목을 제거한다") {
                let current = evaluation(results: [
                    result(id: 1, hash: 10),
                    result(id: 2, hash: 20)
                ])
                let response = WorkspaceEvaluateResponseDto(
                    status: "DELTA",
                    evaluation: evaluation(results: []),
                    deleted: [EntityDto(type: "AB_TEST", id: 1)]
                )

                let merged = try! WorkspaceEvaluationMerger.merge(evaluation: current, response: response)

                expect(merged.results.map { $0.id }) == [2]
            }

            it("response.evaluation이 nil이면 throw한다") {
                let current = evaluation(results: [])
                let response = WorkspaceEvaluateResponseDto(status: "DELTA", evaluation: nil, deleted: [])

                expect {
                    try WorkspaceEvaluationMerger.merge(evaluation: current, response: response)
                }.to(throwError())
            }
        }

        describe("hash") {
            it("hash들을 정렬 후 31 곱셈 누적으로 계산한다") {
                // acc=1 → 1*31+10=41 → 41*31+20=1291 → 1291*31+30=40051
                let results = [result(id: 3, hash: 30), result(id: 1, hash: 10), result(id: 2, hash: 20)]
                expect(WorkspaceEvaluationMerger.hash(results: results)) == 40051
            }

            it("순서가 달라도 같은 hash를 만든다 (정렬)") {
                let a = [result(id: 1, hash: 10), result(id: 2, hash: 20)]
                let b = [result(id: 2, hash: 20), result(id: 1, hash: 10)]
                expect(WorkspaceEvaluationMerger.hash(results: a)) == WorkspaceEvaluationMerger.hash(results: b)
            }

            it("Int32 랩핑 산술로 오버플로해도 크래시 없이 서버(32비트 정수)와 같은 값을 만든다") {
                // acc=1; acc = acc*31 + Int32.max = 2147483678 → Int32 오버플로 = -2147483618
                let results = [result(id: 1, hash: Int32.max)]
                expect(WorkspaceEvaluationMerger.hash(results: results)) == Int32(bitPattern: 0x8000001E)

                // 대량 항목으로도 크래시 없음
                let many = (0..<100).map { i in result(id: Int64(i), hash: Int32.max - Int32(i)) }
                _ = WorkspaceEvaluationMerger.hash(results: many)
            }

            it("빈 리스트는 1이다") {
                expect(WorkspaceEvaluationMerger.hash(results: [])) == 1
            }
        }
    }
}
