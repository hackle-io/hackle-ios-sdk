import Foundation
import Quick
import Nimble
@testable import Hackle

class WorkspaceEvaluationContextSpecs: QuickSpec {
    override class func spec() {

        describe("keyOf(user: HackleUser)") {
            it("SESSION과 HACKLE_DEVICE_ID 식별자는 key에서 제외한다") {
                let user = HackleUser.builder()
                    .identifier(.id, "id_1")
                    .identifier(.user, "user_1")
                    .identifier(.device, "device_1")
                    .identifier(.session, "session_1")
                    .identifier(.hackleDevice, "hackle_device_1")
                    .identifier("custom_type", "custom_1")
                    .build()

                let key = WorkspaceEvaluationContext.keyOf(user: user)

                expect(key.identifiers) == [
                    "$id": "id_1",
                    "$userId": "user_1",
                    "$deviceId": "device_1",
                    "custom_type": "custom_1"
                ]
            }

            it("세션만 바뀐 유저는 같은 key를 가진다") {
                let user1 = HackleUser.builder()
                    .identifier(.id, "id_1")
                    .identifier(.session, "session_1")
                    .build()
                let user2 = HackleUser.builder()
                    .identifier(.id, "id_1")
                    .identifier(.session, "session_2")
                    .build()

                expect(WorkspaceEvaluationContext.keyOf(user: user1)) == WorkspaceEvaluationContext.keyOf(user: user2)
            }
        }

        describe("keyOf(user: User)") {
            it("resolvedIdentifiers 기준으로 key를 만든다") {
                let user = Hackle.user(id: "id_1", userId: "user_1", deviceId: "device_1", identifiers: ["custom_type": "custom_1"])

                let key = WorkspaceEvaluationContext.keyOf(user: user)

                expect(key.identifiers) == [
                    "$id": "id_1",
                    "$userId": "user_1",
                    "$deviceId": "device_1",
                    "custom_type": "custom_1"
                ]
            }
        }

        describe("of / from") {
            it("dto로 DefaultWorkspaceEvaluation을 만들고 원본 dto를 보존한다") {
                let file = Bundle(for: WorkspaceEvaluationContextSpecs.self).path(forResource: "workspace_evaluation_response", ofType: "json")!
                let data = try! Data(contentsOf: URL(fileURLWithPath: file))
                let dto = try! JSONDecoder().decode(WorkspaceEvaluateResponseDto.self, from: data).evaluation!

                let key = WorkspaceEvaluationContext.Key(identifiers: ["$id": "id_1"])
                let context = WorkspaceEvaluationContext.of(key: key, dto: dto, fullEvaluatedAt: 1720000000000)

                expect(context.key) == key
                expect(context.workspace.metadata.id) == 1
                expect(context.dto.results.count) == dto.results.count
                expect(context.fullEvaluatedAt) == 1720000000000

                let record = WorkspaceEvaluationContextDto(key: ["$id": "id_1"], evaluation: dto, fullEvaluatedAt: 1720000000000)
                let restored = WorkspaceEvaluationContext.from(dto: record)
                expect(restored.key) == key
                expect(restored.fullEvaluatedAt) == 1720000000000
            }
        }

        describe("RemoteEvaluateContext") {
            it("of(user:)는 platformType ios, empty operations로 만든다") {
                let user = HackleUser.builder().identifier(.id, "id_1").build()
                let context = RemoteEvaluateContext.of(user: user)

                expect(context.platformType) == PlatformType.ios
                expect(context.operations.count) == 0
                expect(context.key) == WorkspaceEvaluationContext.keyOf(user: user)
            }

            it("toDto는 identifiers·properties·operations를 매핑한다") {
                let user = HackleUser.builder()
                    .identifier(.id, "id_1")
                    .property("age", 30)
                    .hackleProperty("platform", "iOS")
                    .build()
                let operations = PropertyOperations.builder()
                    .set("grade", "GOLD")
                    .build()

                let dto = RemoteEvaluateContext.of(user: user, operations: operations).toDto()

                expect(dto.platformType) == "IOS"
                expect(dto.user.identifiers) == ["$id": "id_1"]
                expect(dto.user.userProperties["age"] as? Int) == 30
                expect(dto.user.hackleProperties["platform"] as? String) == "iOS"
                expect(dto.operations["$set"]?["grade"] as? String) == "GOLD"
            }
        }
    }
}
