import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class UserSpecs: QuickSpec {
    override func spec() {
        it("builder") {
            let user = HackleUserBuilder()
                .id("id")
                .userId("userId")
                .deviceId("deviceId")
                .identifier("customId", "customValue")
                .property("key", "value")
                .property("nil", nil)
                .build()

            expect(user.id) == "id"
            expect(user.userId) == "userId"
            expect(user.deviceId) == "deviceId"
            expect(user.identifiers) == ["customId": "customValue"]
            expect(user.properties["key"] as? String) == "value"
            expect(user.properties["nil"]).to(beNil())

            let user2 = user.toBuilder()
                .identifier("customId2", "customValue2")
                .property("age", 30)
                .build()

            expect(user2.id) == "id"
            expect(user2.userId) == "userId"
            expect(user2.deviceId) == "deviceId"
            expect(user2.identifiers) == ["customId": "customValue", "customId2": "customValue2"]
            expect(user2.properties["key"] as? String) == "value"
            expect(user2.properties["age"] as? Int) == 30
            expect(user.properties["nil"]).to(beNil())
        }
    }
}
