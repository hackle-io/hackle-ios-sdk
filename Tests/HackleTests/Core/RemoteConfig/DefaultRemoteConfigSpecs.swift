//
//  DefaultRemoteConfigSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/7/25.
//

import Quick
import Nimble
@testable import Hackle

class DefaultRemoteConfigSpecs: QuickSpec {
    override class func spec() {
        var user: User?
        var hackleAppCore: MockHackleAppCore!
        var userManager: MockUserManager!
        var config: DefaultRemoteConfig!

        beforeEach {
            user = User.builder().id("user").build()
            hackleAppCore = MockHackleAppCore()
            userManager = MockUserManager()
            config = DefaultRemoteConfig(hackleAppCore: hackleAppCore, user: user)
        }

        it("getString이 remoteConfig 값을 반환한다") {
            every(hackleAppCore.remoteConfigRef)
                .returns(RemoteConfigDecision(value: HackleValue(value: "remoteValue"), reason: ""))
            let result = config.getString(forKey: "key", defaultValue: "default")
            expect(result) == "remoteValue"
        }

        it("getString이 nil이면 default를 반환한다") {
            every(hackleAppCore.remoteConfigRef)
                .returns(RemoteConfigDecision(value: HackleValue(value: 1), reason: ""))
            let result = config.getString(forKey: "key", defaultValue: "default")
            expect(result) == "default"
        }

        it("getInt가 remoteConfig 값을 반환한다") {
            every(hackleAppCore.remoteConfigRef)
                .returns(RemoteConfigDecision(value: HackleValue(value: 42), reason: ""))
            let result = config.getInt(forKey: "key", defaultValue: 1)
            expect(result) == 42
        }

        it("getInt가 nil이면 default를 반환한다") {
            every(hackleAppCore.remoteConfigRef)
                .returns(RemoteConfigDecision(value: HackleValue(value: false), reason: ""))
            let result = config.getInt(forKey: "key", defaultValue: 1)
            expect(result) == 1
        }

        it("getDouble이 remoteConfig 값을 반환한다") {
            every(hackleAppCore.remoteConfigRef)
                .returns(RemoteConfigDecision(value: HackleValue(value: 3.14), reason: ""))
            let result = config.getDouble(forKey: "key", defaultValue: 0.0)
            expect(result) == 3.14
        }

        it("getDouble이 nil이면 default를 반환한다") {
            every(hackleAppCore.remoteConfigRef)
                .returns(RemoteConfigDecision(value: HackleValue(value: "remoteValue"), reason: ""))
            let result = config.getDouble(forKey: "key", defaultValue: 0.0)
            expect(result) == 0.0
        }

        it("getBool이 remoteConfig 값을 반환한다") {
            every(hackleAppCore.remoteConfigRef)
                .returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
            let result = config.getBool(forKey: "key", defaultValue: false)
            expect(result) == true
        }

        it("getBool이 nil이면 default를 반환한다") {
            every(hackleAppCore.remoteConfigRef)
                .returns(RemoteConfigDecision(value: HackleValue(value: "remoteValue"), reason: ""))
            let result = config.getBool(forKey: "key", defaultValue: false)
            expect(result) == false
        }
    }
}

