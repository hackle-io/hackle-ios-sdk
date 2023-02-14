import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultUserManagerSpecs: QuickSpec {
    override func spec() {
        describe("initialize") {
            it("from input") {
                let device = Device(id: "test_device_id", properties: [:])
                let repository = MemoryKeyValueRepository()
                let userManager = DefaultUserManager(device: device, repository: repository)

                let user = HackleUserBuilder().id("hello").build()
                userManager.initialize(user: user)

                expect(userManager.currentUser) == user
            }

            it("from repository") {
                let device = Device(id: "test_device_id", properties: [:])
                let repository = MemoryKeyValueRepository()
                let userManager = DefaultUserManager(device: device, repository: repository)
                let user = HackleUserBuilder()
                    .id("id")
                    .userId("userId")
                    .deviceId("deviceId")
                    .identifier("customId", "customValue")
                    .property("string", "value")
                    .property("int", 42)
                    .property("boolean", false)
                    .property("nil", nil)
                    .build()

                let dict: [String: Any] = [
                    "id": user.id,
                    "userId": user.userId,
                    "deviceId": user.deviceId,
                    "identifiers": user.identifiers,
                    "properties": user.properties
                ]

                repository.putData(key: "user", value: Json.serialize(dict)!)

                userManager.initialize(user: nil)

                expect(userManager.currentUser.id) == "id"
                expect(userManager.currentUser.userId) == "userId"
                expect(userManager.currentUser.deviceId) == "deviceId"
                expect(userManager.currentUser.identifiers) == user.identifiers
            }

            it("from default user") {
                let device = Device(id: "test_device_id", properties: [:])
                let repository = MemoryKeyValueRepository()
                let userManager = DefaultUserManager(device: device, repository: repository)

                userManager.initialize(user: nil)

                expect(userManager.currentUser.deviceId) == "test_device_id"
            }
        }

        describe("setUser") {

            it("기존 사용자와 다른 경우") {
                let device = Device(id: "test_device_id", properties: [:])
                let repository = MemoryKeyValueRepository()
                let userManager = DefaultUserManager(device: device, repository: repository)
                let listener = UserListenerStub()
                userManager.addListener(listener: listener)

                let user = HackleUserBuilder().deviceId("42").build()
                let actual = userManager.setUser(user: user)

                expect(actual.deviceId) == "42"
                expect(listener.history.count) == 1
                expect(listener.history[0].0.deviceId) == "test_device_id"
                expect(listener.history[0].1.deviceId) == "42"
            }


            it("기존 사용자와 다른 경우 2") {
                let device = Device(id: "test_device_id", properties: [:])
                let repository = MemoryKeyValueRepository()
                let userManager = DefaultUserManager(device: device, repository: repository)
                let listener = UserListenerStub()
                userManager.addListener(listener: listener)

                let oldUser = HackleUserBuilder().deviceId("a").property("a", "a").build()
                let newUser = HackleUserBuilder().deviceId("b").property("b", "b").build()

                userManager.initialize(user: oldUser)
                let actual = userManager.setUser(user: newUser)

                expect(actual.deviceId) == "b"
                expect(actual.properties["a"] as? String).to(beNil())
                expect(actual.properties["b"] as? String) == "b"
                expect(listener.history.count) == 1
                expect(listener.history[0].0.deviceId) == "a"
                expect(listener.history[0].1.deviceId) == "b"
            }

            it("기존 사용자와 같은 사용자인 경우") {
                let device = Device(id: "test_device_id", properties: [:])
                let repository = MemoryKeyValueRepository()
                let userManager = DefaultUserManager(device: device, repository: repository)
                let listener = UserListenerStub()
                userManager.addListener(listener: listener)

                let oldUser = HackleUserBuilder().deviceId("a").property("a", "a").build()
                let newUser = HackleUserBuilder().deviceId("a").property("b", "b").build()

                userManager.initialize(user: oldUser)
                let actual = userManager.setUser(user: newUser)

                expect(actual.deviceId) == "a"
                expect(actual.properties["a"] as? String) == "a"
                expect(actual.properties["b"] as? String) == "b"
                expect(listener.history.count) == 0
            }
        }

        describe("onNotified") {
            it("현재 사용자를 저장한다") {
                let device = Device(id: "test_device_id", properties: [:])
                let repository = MemoryKeyValueRepository()
                let userManager = DefaultUserManager(device: device, repository: repository)
                let listener = UserListenerStub()
                userManager.addListener(listener: listener)

                let user = HackleUserBuilder().deviceId("a").property("a", "a").build()
                userManager.initialize(user: user)
                userManager.onNotified(notification: .didEnterBackground, timestamp: Date(timeIntervalSince1970: 42))

                expect(repository.getData(key: "user")).toNot(beNil())
            }
        }
    }
}

fileprivate class UserListenerStub: UserListener {

    var history = [(User, User, Date)]()

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        history.append((oldUser, newUser, timestamp))
    }
}