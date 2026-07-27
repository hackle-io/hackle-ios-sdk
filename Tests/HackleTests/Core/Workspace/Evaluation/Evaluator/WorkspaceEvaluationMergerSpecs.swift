import Foundation
import Quick
import Nimble
@testable import Hackle

class WorkspaceEvaluationMergerSpecs: QuickSpec {
    override class func spec() {

        func workspaceDto(id: Int64 = 1) -> WorkspaceDto {
            let json = #"{"id": \#(id), "environment": {"id": 2}}"#
            return try! JSONDecoder().decode(WorkspaceDto.self, from: json.data(using: .utf8)!)
        }

        func result(type: String = "AB_TEST", id: Int64, hash: Int32) -> EvaluateResultDto {
            EvaluateResultDto(type: type, id: id, hash: hash, experiment: nil, featureFlag: nil, remoteConfig: nil, inAppMessage: nil)
        }

        func metadata(hash: Int32 = 0) -> WorkspaceEvaluationMetadataDto {
            WorkspaceEvaluationMetadataDto(
                hash: hash,
                evaluatedAt: 1720000000000,
                user: HackleUserMetadataDto(hash: 0),
                config: WorkspaceConfigMetadataDto(modifiedAt: "modified_at")
            )
        }

        func evaluation(results: [EvaluateResultDto]) -> WorkspaceEvaluationDto {
            WorkspaceEvaluationDto(workspace: workspaceDto(), metadata: metadata(), results: results)
        }

        func delta(
            workspace: WorkspaceDto = workspaceDto(),
            metadata m: WorkspaceEvaluationMetadataDto,
            changed: [EvaluateResultDto] = [],
            deleted: [EntityDto] = []
        ) -> WorkspaceEvaluationDeltaDto {
            WorkspaceEvaluationDeltaDto(workspace: workspace, metadata: m, changed: changed, deleted: deleted)
        }

        describe("merge") {
            it("같은 (type,id)는 delta로 교체하고 새 항목은 뒤에 추가하며 순서를 보존한다") {
                let current = evaluation(results: [
                    result(id: 1, hash: 10),
                    result(id: 2, hash: 20),
                    result(id: 3, hash: 30)
                ])
                let d = delta(workspace: workspaceDto(id: 9), metadata: metadata(hash: 999), changed: [
                    result(id: 2, hash: 21),
                    result(id: 4, hash: 40)
                ])

                let merged = WorkspaceEvaluationMerger.merge(evaluation: current, delta: d)

                expect(merged.results.map { $0.id }) == [1, 2, 3, 4]
                expect(merged.results.map { $0.hash }) == [10, 21, 30, 40]
                expect(merged.metadata.hash) == 999 // metadata는 delta 것
                expect(merged.workspace.id) == 9 // workspace도 delta 것
            }

            it("type이 다르면 id가 같아도 다른 항목이다") {
                let current = evaluation(results: [result(type: "AB_TEST", id: 1, hash: 10)])
                let d = delta(metadata: metadata(), changed: [result(type: "FEATURE_FLAG", id: 1, hash: 11)])

                let merged = WorkspaceEvaluationMerger.merge(evaluation: current, delta: d)

                expect(merged.results.count) == 2
            }

            it("deleted 항목을 제거한다") {
                let current = evaluation(results: [
                    result(id: 1, hash: 10),
                    result(id: 2, hash: 20)
                ])
                let d = delta(metadata: metadata(), deleted: [EntityDto(type: "AB_TEST", id: 1)])

                let merged = WorkspaceEvaluationMerger.merge(evaluation: current, delta: d)

                expect(merged.results.map { $0.id }) == [2]
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

            it("external-sdk EvaluateResultHasher와 동일한 해시를 만든다 (golden 1000케이스)") {
                let path = Bundle(for: WorkspaceEvaluationMergerSpecs.self).path(forResource: "evaluate_results_hash", ofType: "csv")!
                let content = try! String(contentsOfFile: path, encoding: .utf8)
                for line in content.split(separator: "\n") {
                    let values = line.split(separator: ",").map { Int32($0)! }
                    let expected = values[0]
                    let results = values.dropFirst().enumerated().map { index, hash in
                        result(id: Int64(index), hash: hash)
                    }
                    expect(WorkspaceEvaluationMerger.hash(results: results)) == expected
                }
            }
        }
    }
}
