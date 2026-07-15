import Foundation
import Quick
import Nimble
@testable import Hackle

class FileWorkspaceEvaluationRepositorySpecs: QuickSpec {
    override class func spec() {

        func evaluationDto() -> WorkspaceEvaluationDto {
            let file = Bundle(for: FileWorkspaceEvaluationRepositorySpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            return try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).full!
        }

        func record(id: String) -> WorkspaceEvaluationContext {
            WorkspaceEvaluationContext.of(key: WorkspaceEvaluationContext.Key(identifiers: ["$id": id]), dto: evaluationDto(), fullEvaluatedAt: 0)
        }

        // 구포맷(fullEvaluatedAt 누락) 파일을 재현하기 위한 로컬 dto
        struct OldRecordDto: Codable {
            let key: [String: String]
            let evaluation: WorkspaceEvaluationDto
        }

        var fileStorage: MockFileStorage!
        var sut: FileWorkspaceEvaluationRepository!
        beforeEach {
            fileStorage = MockFileStorage()
            sut = FileWorkspaceEvaluationRepository(fileStorage: fileStorage)
        }

        it("set 후 get으로 round-trip된다 (key·dto 보존)") {
            sut.set(records: [record(id: "1"), record(id: "2")])

            let loaded = sut.get()

            expect(loaded.count) == 2
            expect(loaded.map { $0.key.identifiers["$id"] }) == ["1", "2"]
            expect(loaded[0].workspace.metadata.id) == 1
            expect(loaded[0].dto.results.count) == record(id: "1").dto.results.count
        }

        it("파일이 없으면 빈 배열을 반환한다") {
            expect(sut.get()).to(beEmpty())
        }

        it("파일이 파손되면 삭제하고 빈 배열을 반환한다") {
            try! fileStorage.write(filename: "workspace_evaluation.json", data: "not-json".data(using: .utf8)!)

            expect(sut.get()).to(beEmpty())
            expect(fileStorage.exists(filename: "workspace_evaluation.json")) == false
        }

        it("fileStorage가 nil이면 get은 빈 배열, set은 no-op이다") {
            let sut = FileWorkspaceEvaluationRepository(fileStorage: nil)
            sut.set(records: [record(id: "1")])
            expect(sut.get()).to(beEmpty())
        }

        it("fullEvaluatedAt이 없는 구포맷 파일은 삭제하고 빈 배열을 반환한다") {
            let fileStorage = MockFileStorage()
            let sut = FileWorkspaceEvaluationRepository(fileStorage: fileStorage)
            let old = [OldRecordDto(key: ["$id": "a"], evaluation: evaluationDto())]
            try! fileStorage.write(filename: "workspace_evaluation.json", data: JSONEncoder().encode(old))

            let contexts = sut.get()

            expect(contexts).to(beEmpty())
            expect(fileStorage.exists(filename: "workspace_evaluation.json")) == false
        }

        it("fullEvaluatedAt을 저장하고 복원한다") {
            let fileStorage = MockFileStorage()
            let sut = FileWorkspaceEvaluationRepository(fileStorage: fileStorage)
            let context = WorkspaceEvaluationContext.of(
                key: WorkspaceEvaluationContext.Key(identifiers: ["$id": "1"]),
                dto: evaluationDto(),
                fullEvaluatedAt: 1720000000000
            )
            sut.set(records: [context])

            let restored = sut.get()

            expect(restored[0].fullEvaluatedAt) == 1720000000000
        }
    }
}
