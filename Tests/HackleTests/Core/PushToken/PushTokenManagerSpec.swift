import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class PushTokenManagerSpec: QuickSpec {
    override func spec() {
        var core: HackleCoreStub!
        var preferences: MemoryKeyValueRepository!
        var userManager: MockUserManager!
        var dataSource: MockPushTokenDataSource!
        
        beforeEach {
            core = HackleCoreStub()
            preferences = MemoryKeyValueRepository()
            userManager = MockUserManager()
            dataSource = MockPushTokenDataSource()
        }
        
        it("initialize") {
            let manager = DefaultPushTokenManager(
                core: core,
                userManager: userManager,
                preferences: preferences,
                dataSource: dataSource
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            dataSource.pushToken = "foobar"
            
            manager.initialize()
            
            expect(core.tracked.count) == 1
            expect(core.tracked[0].0.key) == "$push_token"
            expect(core.tracked[0].0.properties?["provider_type"] as? String) == "APN"
            expect(core.tracked[0].0.properties?["token"] as? String) == "foobar"
            expect(preferences.getString(key: "push_token")) == "foobar"
        }
        
        it("initialize with another push token") {
            preferences.putString(key: "push_token", value: "foobar")
            let manager = DefaultPushTokenManager(
                core: core,
                userManager: userManager,
                preferences: preferences,
                dataSource: dataSource
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            dataSource.pushToken = "barfoo"
            
            manager.initialize()
            
            expect(core.tracked.count) == 1
            expect(core.tracked[0].0.key) == "$push_token"
            expect(core.tracked[0].0.properties?["provider_type"] as? String) == "APN"
            expect(core.tracked[0].0.properties?["token"] as? String) == "barfoo"
            expect(preferences.getString(key: "push_token")) == "barfoo"
        }
        
        it("initialize with same push token taken") {
            preferences.putString(key: "push_token", value: "foobar")
            let manager = DefaultPushTokenManager(
                core: core,
                userManager: userManager,
                preferences: preferences,
                dataSource: dataSource
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "user")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            dataSource.pushToken = "foobar"
            
            manager.initialize()
            
            expect(core.tracked.count) == 0
            expect(preferences.getString(key: "push_token")) == "foobar"
        }
        
        it("user has been changed and track register push token event") {
            preferences.putString(key: "push_token", value: "foobar")
            let manager = DefaultPushTokenManager(
                core: core,
                userManager: userManager,
                preferences: preferences,
                dataSource: dataSource
            )
            let oldUser = User.builder()
                .id("foo")
                .build()
            let newUser = User.builder()
                .id("bar")
                .build()
            let hackleUser = HackleUser.builder()
                .identifier(.id, "bar")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            let timestamp = Date()
            manager.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: timestamp)
            
            expect(core.tracked.count) == 1
            expect(core.tracked[0].0.key) == "$push_token"
            expect(core.tracked[0].0.properties?["provider_type"] as? String) == "APN"
            expect(core.tracked[0].0.properties?["token"] as? String) == "foobar"
            expect(core.tracked[0].2.timeIntervalSince1970) == timestamp.timeIntervalSince1970
            expect(preferences.getString(key: "push_token")) == "foobar"
        }
        
        it("user has been changed but do not track event when saved push token is nil") {
            let manager = DefaultPushTokenManager(
                core: core,
                userManager: userManager,
                preferences: preferences,
                dataSource: dataSource
            )
            let oldUser = User.builder()
                .id("foo")
                .build()
            let newUser = User.builder()
                .id("bar")
                .build()
            let hackleUser = HackleUser.builder()
                .identifier(.id, "bar")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            let timestamp = Date()
            dataSource.pushToken = "abcd1234"
            manager.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: timestamp)
            
            expect(core.tracked.count) == 0
            expect(preferences.getString(key: "push_token")).to(beNil())
        }
        
        it("set fresh new push token") {
            let manager = DefaultPushTokenManager(
                core: core,
                userManager: userManager,
                preferences: preferences,
                dataSource: dataSource
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "bar")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            let timestamp = Date()
            manager.setPushToken(pushToken: "foobar", timestamp: timestamp)
            
            expect(core.tracked.count) == 1
            expect(core.tracked[0].0.key) == "$push_token"
            expect(core.tracked[0].0.properties?["provider_type"] as? String) == "APN"
            expect(core.tracked[0].0.properties?["token"] as? String) == "foobar"
            expect(core.tracked[0].2.timeIntervalSince1970) == timestamp.timeIntervalSince1970
            expect(preferences.getString(key: "push_token")) == "foobar"
        }
        
        it("set same push token") {
            preferences.putString(key: "push_token", value: "foobar")
            let manager = DefaultPushTokenManager(
                core: core,
                userManager: userManager,
                preferences: preferences,
                dataSource: dataSource
            )
            let hackleUser = HackleUser.builder()
                .identifier(.id, "bar")
                .build()
            every(userManager.toHackleUserMock).returns(hackleUser)
            
            let timestamp = Date()
            manager.setPushToken(pushToken: "foobar", timestamp: timestamp)
            
            expect(core.tracked.count) == 0
            expect(preferences.getString(key: "push_token")) == "foobar"
        }
    }
}
