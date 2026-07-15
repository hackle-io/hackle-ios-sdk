import Foundation
import Quick
import Nimble
@testable import Hackle

class LruWorkspaceEvaluationCacheSpecs: QuickSpec {
    override class func spec() {

        func record(id: String) -> WorkspaceEvaluationContext {
            let file = Bundle(for: LruWorkspaceEvaluationCacheSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
            let data = try! Data(contentsOf: URL(fileURLWithPath: file))
            let dto = try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).full!
            return WorkspaceEvaluationContext.of(key: WorkspaceEvaluationContext.Key(identifiers: ["$id": id]), dto: dto, fullEvaluatedAt: 0)
        }

        var sut: LruWorkspaceEvaluationCache!
        beforeEach {
            sut = LruWorkspaceEvaluationCache(capacity: 3)
        }

        it("get은 저장된 record를 key로 반환하고 없으면 nil이다") {
            let r1 = record(id: "1")
            _ = sut.put(record: r1)

            expect(sut.get(key: r1.key)).toNot(beNil())
            expect(sut.get(key: WorkspaceEvaluationContext.Key(identifiers: ["$id": "none"]))).to(beNil())
        }

        it("put은 전체 스냅샷을 오래된 순으로 반환한다") {
            _ = sut.put(record: record(id: "1"))
            let snapshots = sut.put(record: record(id: "2"))

            expect(snapshots.map { $0.key.identifiers["$id"] }) == ["1", "2"]
        }

        it("capacity 초과 시 가장 오래된 record를 evict한다") {
            _ = sut.put(record: record(id: "1"))
            _ = sut.put(record: record(id: "2"))
            _ = sut.put(record: record(id: "3"))
            let snapshots = sut.put(record: record(id: "4"))

            expect(snapshots.map { $0.key.identifiers["$id"] }) == ["2", "3", "4"]
            expect(sut.get(key: WorkspaceEvaluationContext.Key(identifiers: ["$id": "1"]))).to(beNil())
        }

        it("같은 key를 다시 put하면 순서가 최신으로 갱신된다") {
            _ = sut.put(record: record(id: "1"))
            _ = sut.put(record: record(id: "2"))
            _ = sut.put(record: record(id: "1")) // 재삽입
            let snapshots = sut.put(record: record(id: "3"))

            expect(snapshots.map { $0.key.identifiers["$id"] }) == ["2", "1", "3"]
        }

        it("latest는 가장 최근 put된 record를 반환한다") {
            expect(sut.latest()).to(beNil())

            _ = sut.put(record: record(id: "1"))
            _ = sut.put(record: record(id: "2"))

            expect(sut.latest()?.key.identifiers["$id"]) == "2"
        }

        it("restore는 기존 항목을 비우고 뒤에서 capacity개만 복원한다") {
            _ = sut.put(record: record(id: "old"))

            sut.restore(records: [record(id: "1"), record(id: "2"), record(id: "3"), record(id: "4")])

            expect(sut.get(key: WorkspaceEvaluationContext.Key(identifiers: ["$id": "old"]))).to(beNil())
            expect(sut.get(key: WorkspaceEvaluationContext.Key(identifiers: ["$id": "1"]))).to(beNil()) // suffix(3) 밖
            expect(sut.latest()?.key.identifiers["$id"]) == "4"
        }
    }
}
