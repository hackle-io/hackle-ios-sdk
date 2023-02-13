//
//  DefaultHackleUserResolverSpecs.swift
//  HackleTests
//
//  Created by yong on 2022/05/29.
//

import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultHackleUserResolverSpecs: QuickSpec {
    override func spec() {
        it("resolve") {
            let device = Device(id: "hackleDeviceId", properties: ["key": "hackle_value"])
            let resolver = DefaultHackleUserResolver(device: device)

            let user = User.builder()
                .id("id")
                .userId("userId")
                .deviceId("deviceId")
                .identifier("customId", "customValue")
                .property("key", "user_value")
                .build()

            let hackleUser = resolver.resolve(user: user)

            expect(hackleUser.identifiers) == [
                "customId": "customValue",
                "$id": "id",
                "$userId": "userId",
                "$deviceId": "deviceId",
                "$hackleDeviceId": "hackleDeviceId",
            ]
            expect(hackleUser.properties.count) == 1
            expect(hackleUser.properties["key"] as? String) == "user_value"

            expect(hackleUser.hackleProperties.count) == 1
            expect(hackleUser.hackleProperties["key"] as? String) == "hackle_value"
        }

        it("식별자 없는 경우") {
            let device = Device(id: "hackleDeviceId", properties: ["key": "hackle_value"])
            let resolver = DefaultHackleUserResolver(device: device)

            let hackleUser = resolver.resolve(user: User.builder().build())

            expect(hackleUser.identifiers) == [
                "$id": "hackleDeviceId",
                "$deviceId": "hackleDeviceId",
                "$hackleDeviceId": "hackleDeviceId",
            ]
        }
    }
}
