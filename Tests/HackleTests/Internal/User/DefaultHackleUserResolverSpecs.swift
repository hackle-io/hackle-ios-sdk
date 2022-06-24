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

        it("deviceId가 없으면 내부에서 생성된 deviceId를 설정한다") {
            // given
            let user = Hackle.user()

            let device = Device(id: "abc123", properties: [:])
            let sut = DefaultHackleUserResolver(device: device)

            // when
            let actual = sut.resolveOrNil(user: user)

            // then
            expect(actual).notTo(beNil())
            expect(actual?.identifiers["$deviceId"]) == "abc123"
        }

        it("deviceId가 있으면 그대로 사용한다") {
            // given
            let user = Hackle.user(deviceId: "999")

            let device = Device(id: "abc123", properties: [:])
            let sut = DefaultHackleUserResolver(device: device)

            // when
            let actual = sut.resolveOrNil(user: user)

            // then
            expect(actual).notTo(beNil())
            expect(actual?.identifiers["$deviceId"]) == "999"
        }

        it("resolve") {
            // given
            let user = Hackle.user(id: "id", userId: "userId", deviceId: "deviceId", identifiers: ["customId": "customId"], properties: ["age": 30])

            let device = Device(id: "internal_device_id", properties: ["os": "ios"])
            let sut = DefaultHackleUserResolver(device: device)

            // when
            let actual = sut.resolveOrNil(user: user)

            // then
            expect(actual).notTo(beNil())
            expect(actual?.identifiers["$id"]) == "id"
            expect(actual?.identifiers["$userId"]) == "userId"
            expect(actual?.identifiers["$deviceId"]) == "deviceId"
            expect(actual?.identifiers["customId"]) == "customId"
            expect(actual?.properties["age"] as? Int) == 30
            expect(actual?.hackleProperties["os"] as? String) == "ios"
        }
    }
}