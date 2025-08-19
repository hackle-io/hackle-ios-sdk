//
//  ContextRemoteConfigSpecs.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/18/25.
//

import Quick
import Nimble
@testable import Hackle

class ContextRemoteConfigSpecs: QuickSpec {
    override func spec() {
        var user: User?
        var app: MockHackleCore!
        var userManager: MockUserManager!
        var config: ContextRemoteConfig!
        let hackleAppContext = HackleAppContext.create(browserProperties: [
            "browser": "safari",
            "path": "/",
            "query": "key=value",
        ])

        beforeEach {
            user = User.builder().id("user").build()
            app = MockHackleCore()
            userManager = MockUserManager()
            config = ContextRemoteConfig(user: user, app: app, userManager: userManager, hackleAppContext: hackleAppContext)
        }

        it("getString이 remoteConfig 값을 반환한다") {
            every(app.remoteConfigMock)
                .returns(RemoteConfigDecision(value: HackleValue(value: "remoteValue"), reason: ""))
            let result = config.getString(forKey: "key", defaultValue: "default")
            expect(result) == "remoteValue"
            verify(exactly: 1) {
                userManager.resolveMock
            }
            expect(userManager.resolveMock.firstInvokation().arguments.0) == user
            userManager.resolveMock.firstInvokation().arguments.1.browserProperties.forEach { key, value in
                expect(hackleAppContext.browserProperties[key]).toNot(beNil())
                expect(hackleAppContext.browserProperties[key] as? String) == value as? String
            }
        }

        it("getString이 nil이면 default를 반환한다") {
            every(app.remoteConfigMock)
                .returns(RemoteConfigDecision(value: HackleValue(value: 1), reason: ""))
            let result = config.getString(forKey: "key", defaultValue: "default")
            expect(result) == "default"
            verify(exactly: 1) {
                userManager.resolveMock
            }
            expect(userManager.resolveMock.firstInvokation().arguments.0) == user
            userManager.resolveMock.firstInvokation().arguments.1.browserProperties.forEach { key, value in
                expect(hackleAppContext.browserProperties[key]).toNot(beNil())
                expect(hackleAppContext.browserProperties[key] as? String) == value as? String
            }
        }

        it("getInt가 remoteConfig 값을 반환한다") {
            every(app.remoteConfigMock)
                .returns(RemoteConfigDecision(value: HackleValue(value: 42), reason: ""))
            let result = config.getInt(forKey: "key", defaultValue: 1)
            expect(result) == 42
            verify(exactly: 1) {
                userManager.resolveMock
            }
            expect(userManager.resolveMock.firstInvokation().arguments.0) == user
            userManager.resolveMock.firstInvokation().arguments.1.browserProperties.forEach { key, value in
                expect(hackleAppContext.browserProperties[key]).toNot(beNil())
                expect(hackleAppContext.browserProperties[key] as? String) == value as? String
            }
        }

        it("getInt가 nil이면 default를 반환한다") {
            every(app.remoteConfigMock)
                .returns(RemoteConfigDecision(value: HackleValue(value: false), reason: ""))
            let result = config.getInt(forKey: "key", defaultValue: 1)
            expect(result) == 1
            verify(exactly: 1) {
                userManager.resolveMock
            }
            expect(userManager.resolveMock.firstInvokation().arguments.0) == user
            userManager.resolveMock.firstInvokation().arguments.1.browserProperties.forEach { key, value in
                expect(hackleAppContext.browserProperties[key]).toNot(beNil())
                expect(hackleAppContext.browserProperties[key] as? String) == value as? String
            }
        }

        it("getDouble이 remoteConfig 값을 반환한다") {
            every(app.remoteConfigMock)
                .returns(RemoteConfigDecision(value: HackleValue(value: 3.14), reason: ""))
            let result = config.getDouble(forKey: "key", defaultValue: 0.0)
            expect(result) == 3.14
            verify(exactly: 1) {
                userManager.resolveMock
            }
            expect(userManager.resolveMock.firstInvokation().arguments.0) == user
            userManager.resolveMock.firstInvokation().arguments.1.browserProperties.forEach { key, value in
                expect(hackleAppContext.browserProperties[key]).toNot(beNil())
                expect(hackleAppContext.browserProperties[key] as? String) == value as? String
            }
        }

        it("getDouble이 nil이면 default를 반환한다") {
            every(app.remoteConfigMock)
                .returns(RemoteConfigDecision(value: HackleValue(value: "remoteValue"), reason: ""))
            let result = config.getDouble(forKey: "key", defaultValue: 0.0)
            expect(result) == 0.0
            verify(exactly: 1) {
                userManager.resolveMock
            }
            expect(userManager.resolveMock.firstInvokation().arguments.0) == user
            userManager.resolveMock.firstInvokation().arguments.1.browserProperties.forEach { key, value in
                expect(hackleAppContext.browserProperties[key]).toNot(beNil())
                expect(hackleAppContext.browserProperties[key] as? String) == value as? String
            }
        }

        it("getBool이 remoteConfig 값을 반환한다") {
            every(app.remoteConfigMock)
                .returns(RemoteConfigDecision(value: HackleValue(value: true), reason: ""))
            let result = config.getBool(forKey: "key", defaultValue: false)
            expect(result) == true
            verify(exactly: 1) {
                userManager.resolveMock
            }
            expect(userManager.resolveMock.firstInvokation().arguments.0) == user
            userManager.resolveMock.firstInvokation().arguments.1.browserProperties.forEach { key, value in
                expect(hackleAppContext.browserProperties[key]).toNot(beNil())
                expect(hackleAppContext.browserProperties[key] as? String) == value as? String
            }
        }

        it("getBool이 nil이면 default를 반환한다") {
            every(app.remoteConfigMock)
                .returns(RemoteConfigDecision(value: HackleValue(value: "remoteValue"), reason: ""))
            let result = config.getBool(forKey: "key", defaultValue: false)
            expect(result) == false
            verify(exactly: 1) {
                userManager.resolveMock
            }
            expect(userManager.resolveMock.firstInvokation().arguments.0) == user
            userManager.resolveMock.firstInvokation().arguments.1.browserProperties.forEach { key, value in
                expect(hackleAppContext.browserProperties[key]).toNot(beNil())
                expect(hackleAppContext.browserProperties[key] as? String) == value as? String
            }
        }
    }
}

