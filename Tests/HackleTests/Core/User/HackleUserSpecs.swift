import Foundation
import Nimble
import Quick
@testable import Hackle


class HackleUserSpecs: QuickSpec {
    override func spec() {

        it("HackleUser") {
            let user = HackleUser.builder()
                .identifiers(["type-1": "value-1"])
                .identifier("type-2", "value-2")
                .identifier(.id, "id")
                .identifier(.user, "userId")
                .identifier(.device, "deviceId")
                .identifier(.hackleDevice, "hackleDeviceId")
                .identifier(.session, "sessionId")
                .properties(["key-1": "value-1"])
                .property("key-2", "value-2")
                .hackleProperties(["hkey-1": "hvalue-1"])
                .hackleProperty("hkey-2", "hvalue-2")
                .cohort(Cohort(id: 42))
                .cohorts([Cohort(id: 43), Cohort(id: 44)])
                .build()

            expect(user.id) == "id"
            expect(user.userId) == "userId"
            expect(user.deviceId) == "deviceId"
            expect(user.sessionId) == "sessionId"
            expect(user.identifiers) == [
                "type-1": "value-1",
                "type-2": "value-2",
                "$id": "id",
                "$userId": "userId",
                "$deviceId": "deviceId",
                "$hackleDeviceId": "hackleDeviceId",
                "$sessionId": "sessionId",
            ]

            expect(user.properties.count) == 2
            expect(user.properties["key-1"] as? String) == "value-1"
            expect(user.properties["key-2"] as? String) == "value-2"

            expect(user.hackleProperties.count) == 2
            expect(user.hackleProperties["hkey-1"] as? String) == "hvalue-1"
            expect(user.hackleProperties["hkey-2"] as? String) == "hvalue-2"

            expect(user.cohorts.count) == 3
        }
    }
}
