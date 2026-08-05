import Foundation
import Quick
import Nimble
@testable import Hackle

/// `order`가 없는 페이로드(구버전 SDK 캐시, order 도입 전 config 응답) 하위호환 스펙.
/// order 누락이 워크스페이스 전체 디코드를 실패시키면 안 되고, 누락된 order는 0으로 매핑되어
/// payload 순서가 유지되어야 한다(android Gson primitive 기본값과 동일한 의미론).
class WorkspaceConfigOrderCompatSpecs: QuickSpec {

    private static func readData(filename: String) -> Data {
        let path = Bundle(for: WorkspaceConfigOrderCompatSpecs.self).path(forResource: filename, ofType: "json")!
        return try! Data(contentsOf: URL(fileURLWithPath: path))
    }

    override class func spec() {
        describe("order 키가 없는 workspace config 하위호환") {

            it("experiment/featureFlag를 디코드하고 order 0으로 payload 순서를 유지한다") {
                let stripped = try JSONDecoder().decode(WorkspaceConfigRecordDto.self, from: readData(filename: "workspace_config_without_order"))
                let original = try JSONDecoder().decode(WorkspaceConfigRecordDto.self, from: readData(filename: "workspace_config"))

                let strippedConfig = DefaultWorkspaceConfig.from(dto: stripped.config, modifiedAt: nil)
                let originalConfig = DefaultWorkspaceConfig.from(dto: original.config, modifiedAt: nil)

                expect(strippedConfig.experiments.count).to(beGreaterThan(0))
                expect(strippedConfig.experiments.allSatisfy { $0.order == 0 }).to(beTrue())
                expect(strippedConfig.featureFlags.allSatisfy { $0.order == 0 }).to(beTrue())

                // order가 전부 0이어도(stable sort) 구성원과 순서는 order가 있던 결과와 동일해야 한다
                expect(strippedConfig.experiments.map { $0.key }) == originalConfig.experiments.map { $0.key }
                expect(strippedConfig.featureFlags.map { $0.key }) == originalConfig.featureFlags.map { $0.key }
            }

            it("inAppMessage를 디코드하고 order 0으로 payload 순서를 유지한다") {
                let stripped = try JSONDecoder().decode(WorkspaceConfigDto.self, from: readData(filename: "iam_without_order"))
                let original = try JSONDecoder().decode(WorkspaceConfigDto.self, from: readData(filename: "iam"))

                let strippedConfig = DefaultWorkspaceConfig.from(dto: stripped, modifiedAt: nil)
                let originalConfig = DefaultWorkspaceConfig.from(dto: original, modifiedAt: nil)

                expect(strippedConfig.inAppMessages.count).to(beGreaterThan(0))
                expect(strippedConfig.inAppMessages.allSatisfy { $0.order == 0 }).to(beTrue())
                expect(strippedConfig.inAppMessages.map { $0.key }) == originalConfig.inAppMessages.map { $0.key }
            }

            it("구버전 SDK가 저장한 캐시 파일을 삭제하지 않고 로드한다") {
                let mockFileStorage = MockFileStorage(
                    initialData: ["workspace.json": readData(filename: "workspace_config_without_order")]
                )
                let repository = DefaultWorkspaceConfigRepository(fileStorage: mockFileStorage)

                expect(repository.get()).toNot(beNil())
                expect(mockFileStorage.data["workspace.json"]).toNot(beNil())
            }

            it("order가 있는 config는 order 오름차순으로 정렬한다") {
                let original = try JSONDecoder().decode(WorkspaceConfigRecordDto.self, from: readData(filename: "workspace_config"))
                let config = DefaultWorkspaceConfig.from(dto: original.config, modifiedAt: nil)

                expect(config.experiments.count).to(beGreaterThan(0))
                expect(config.experiments.map { $0.order }) == config.experiments.map { $0.order }.sorted()
                expect(config.featureFlags.map { $0.order }) == config.featureFlags.map { $0.order }.sorted()
            }
        }
    }
}
