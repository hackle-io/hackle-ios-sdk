import Foundation
import Quick
import Nimble
@testable import Hackle

class RemoteUserContextSpecs: QuickSpec {
    override class func spec() {

        it("from(user:)는 properties를 비운다 (식별자 전용)") {
            let user = HackleUserBuilder()
                .id("id_1")
                .userId("user_1")
                .deviceId("device_1")
                .identifier("custom_type", "custom_1")
                .property("age", 30)
                .build()

            let context = RemoteUserContext.from(user: user)

            expect(context.user.id) == "id_1"
            expect(context.user.userId) == "user_1"
            expect(context.user.deviceId) == "device_1"
            expect(context.user.identifiers["custom_type"]) == "custom_1"
            expect(context.user.properties.isEmpty) == true
        }

        it("properties가 이미 비어 있으면 유저를 그대로 쓴다") {
            let user = HackleUserBuilder().id("id_1").build()
            let context = RemoteUserContext.from(user: user)
            expect(context.user) === user
        }

        it("evaluationKey는 resolvedIdentifiers 기반 keyOf와 같다") {
            let user = HackleUserBuilder().id("id_1").deviceId("device_1").build()
            let context = RemoteUserContext.from(user: user)
            expect(context.evaluationKey) == WorkspaceEvaluationContext.keyOf(user: user)
        }
    }
}
