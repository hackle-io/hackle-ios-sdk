import Foundation
import Quick
import Nimble
@testable import Hackle


class DefaultUserManagerSpecs: QuickSpec {
    override func spec() {
        var repository: KeyValueRepository!
        var cohortFetcher: MockUserCohortFetcher!
        var clock: Clock!
        var device: Device!
        var sut: DefaultUserManager!

        var listener: MockUserListener!

        beforeEach {
            repository = MemoryKeyValueRepository()
            cohortFetcher = MockUserCohortFetcher()
            clock = FixedClock(date: Date(timeIntervalSince1970: 42))
            device = DeviceImpl(id: "hackle_device_id", platform: MockPlatform())
            sut = DefaultUserManager(device: device, repository: repository, cohortFetcher: cohortFetcher, clock: clock)

            listener = MockUserListener()
            sut.addListener(listener: listener)
        }

        describe("initialize") {
            it("with default user") {
                sut.initialize(user: nil)
                let user = sut.currentUser
                expect(user.resolvedIdentifiers) == ["$id": "hackle_device_id", "$deviceId": "hackle_device_id"]
            }

            it("with saved user") {
                repository.putData(key: "user", value: Json.serialize([
                    "deviceId": "saved_device_id",
                    "userId": "saved_user_id",
                ])!)
                sut.initialize(user: nil)
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "saved_device_id",
                    "$userId": "saved_user_id",
                ]
            }

            it("with init user") {
                repository.putData(key: "user", value: Json.serialize([
                    "deviceId": "saved_device_id",
                    "userId": "saved_user_id",
                ])!)
                sut.initialize(user: User.builder().deviceId("init_device_id").userId("init_user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "init_device_id",
                    "$userId": "init_user_id",
                ]
            }
        }

        describe("resolve") {
            it("currentUser") {
                sut.initialize(user: User.builder().id("init_id").deviceId("init_device_id").userId("init_user_id").build())
                let actual = sut.resolve(user: nil)
                expect(actual.identifiers) == [
                    "$id": "init_id",
                    "$deviceId": "init_device_id",
                    "$userId": "init_user_id",
                    "$hackleDeviceId": "hackle_device_id"
                ]
            }

            it("inputUser") {
                sut.initialize(user: nil)
                let actual = sut.resolve(user: User.builder().id("input_id").build())
                expect(actual.identifiers) == [
                    "$id": "input_id",
                    "$deviceId": "hackle_device_id",
                    "$hackleDeviceId": "hackle_device_id"
                ]
            }
        }

        describe("toHackleUser") {
            it("merge with current context") {
                // given
                let userCohorts = UserCohorts.builder()
                    .put(cohort: UserCohort(identifier: Identifier(type: "$id", value: "id"), cohorts: [Cohort(id: 42)]))
                    .build()
                every(cohortFetcher.fetchMock).answers { user, completion in
                    completion(.success(userCohorts))
                }

                // when
                sut.initialize(user: User.builder().id("id").property("a", "a").build())
                sut.sync {
                }
                let hackleUser = sut.toHackleUser(user: User.builder().id("id").userId("user_id").property("b", "b").build())

                // then
                expect(hackleUser.identifiers) == [
                    "$id": "id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id",
                    "$hackleDeviceId": "hackle_device_id"
                ]
                expect(hackleUser.properties as? [String: String]) == ["b": "b"]
                expect(hackleUser.cohorts) == [Cohort(id: 42)]
            }

            it("full") {
                let hackleUser = sut.toHackleUser(user: User.builder()
                    .id("id")
                    .deviceId("device_id")
                    .userId("user_id")
                    .identifier("custom", "custom_id")
                    .property("age", 42)
                    .build()
                )

                expect(hackleUser.identifiers) == [
                    "$id": "id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                    "$hackleDeviceId": "hackle_device_id",
                    "custom": "custom_id"
                ]
                expect(hackleUser.properties as? [String: Int]) == ["age": 42]
            }

            it("fill default id") {
                let hackleUser = sut.toHackleUser(user: User.builder().build())
                expect(hackleUser.identifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$hackleDeviceId": "hackle_device_id"
                ]
            }

            it("hackle properties") {
                let hackleUser = sut.toHackleUser(user: User.builder().build())
                expect(hackleUser.hackleProperties.count) > 0
            }
        }

        describe("sync") {
            it("update userCohorts") {
                let userCohorts = UserCohorts.builder()
                    .put(cohort: UserCohort(identifier: Identifier(type: "$id", value: "hackle_device_id"), cohorts: [Cohort(id: 42)]))
                    .build()
                every(cohortFetcher.fetchMock).answers { user, completion in
                    completion(.success(userCohorts))
                }

                sut.initialize(user: nil)
                expect(sut.resolve(user: nil).cohorts) == []
                sut.sync {
                }
                expect(sut.resolve(user: nil).cohorts) == [Cohort(id: 42)]
            }

            it("when error on fetch cohort then do not update cohort") {
                // given
                every(cohortFetcher.fetchMock).answers { user, completion in
                    completion(.failure(HackleError.error("fail")))
                }

                sut.initialize(user: nil)
                expect(sut.resolve(user: nil).cohorts) == []
                sut.sync {
                }
                expect(sut.resolve(user: nil).cohorts) == []
            }
        }

        describe("setUser") {
            it("decorate hackleDeviceId") {
                let actual = sut.setUser(user: User.builder().build())
                expect(actual.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]
            }

            it("defaultUser -> deviceId") {
                sut.initialize(user: nil)
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
            }

            it("defaultUser -> deviceId, userId") {
                sut.initialize(user: nil)
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id").userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]
            }

            it("deviceId -> deviceId(diff)") {
                sut.initialize(user: User.builder().deviceId("device_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id_2").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                ]
            }

            it("deviceId -> deviceId, userId(new)") {
                sut.initialize(user: User.builder().deviceId("device_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id").userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]
            }

            it("deviceId -> deviceId(diff), userId(new)") {
                sut.initialize(user: User.builder().deviceId("device_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id_2").userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                    "$userId": "user_id",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                    "$userId": "user_id",
                ]
            }

            it("deviceId, userId -> deviceId") {
                sut.initialize(user: User.builder().deviceId("device_id").userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
            }

            it("deviceId, userId -> deviceId(diff)") {
                sut.initialize(user: User.builder().deviceId("device_id").userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id_2").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                ]
            }

            it("deviceId, userId -> deviceId(diff), userId") {
                sut.initialize(user: User.builder().deviceId("device_id").userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id_2").userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                    "$userId": "user_id",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                    "$userId": "user_id",
                ]
            }

            it("deviceId, userId -> deviceId, userId(diff)") {
                sut.initialize(user: User.builder().deviceId("device_id").userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]

                sut.setUser(user: User.builder().deviceId("device_id").userId("user_id_2").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id_2",
                ]
                let (oldUser, newUser, _) = listener.onUserUpdatedMock.firstInvokation().arguments
                expect(oldUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id",
                ]
                expect(newUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                    "$userId": "user_id_2",
                ]
            }

            it("update cohorts") {
                let userCohorts = UserCohorts.builder()
                    .put(cohort: UserCohort(identifier: Identifier(type: "$id", value: "hackle_device_id"), cohorts: [Cohort(id: 42)]))
                    .put(cohort: UserCohort(identifier: Identifier(type: "$deviceId", value: "hackle_device_id"), cohorts: [Cohort(id: 43)]))
                    .build()
                every(cohortFetcher.fetchMock).answers { user, completion in
                    completion(.success(userCohorts))
                }

                sut.initialize(user: nil)
                sut.sync {
                }

                sut.setUser(user: User.builder().deviceId("device_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                expect(sut.resolve(user: nil).cohorts) == [Cohort(id: 42)]
            }
        }

        describe("updateUserProperties") {
            it("update") {
                sut.initialize(user: nil)

                let operations = PropertyOperations.builder()
                    .set("d", "d")
                    .increment("a", 42)
                    .append("c", "cc")
                    .build()
                let actual = sut.updateProperties(operations: operations)
                expect(actual.properties["a"] as? Double) == 42.0
                expect(actual.properties["c"] as? [String]) == ["cc"]
                expect(actual.properties["d"] as? String) == "d"
            }

            it("existed properties") {
                sut.initialize(user: User.builder()
                    .properties([
                        "a": 42,
                        "b": "b",
                        "c": "c",
                    ])
                    .build()
                )

                let operations = PropertyOperations.builder()
                    .set("d", "d")
                    .increment("a", 42)
                    .append("c", "cc")
                    .build()
                let actual = sut.updateProperties(operations: operations)

                expect(actual.properties["a"] as? Double) == 84.0
                expect(actual.properties["b"] as? String) == "b"
                expect(actual.properties["c"] as? [String]) == ["c", "cc"]
                expect(actual.properties["d"] as? String) == "d"
            }
        }

        describe("setUserId") {
            it("new") {
                sut.initialize(user: nil)
                let actual = sut.setUserId(userId: "user_id")
                expect(actual.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id",
                ]
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id",
                ]
                verify(exactly: 1) {
                    listener.onUserUpdatedMock
                }
            }

            it("unset") {
                sut.initialize(user: User.builder().userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id",
                ]

                let actual = sut.setUserId(userId: nil)
                expect(actual.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]
                verify(exactly: 1) {
                    listener.onUserUpdatedMock
                }
            }

            it("change") {
                sut.initialize(user: User.builder().userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id",
                ]

                let actual = sut.setUserId(userId: "user_id_2")
                expect(actual.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id_2",
                ]
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id_2",
                ]
                verify(exactly: 1) {
                    listener.onUserUpdatedMock
                }
            }

            it("same") {
                sut.initialize(user: User.builder().userId("user_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id",
                ]

                let actual = sut.setUserId(userId: "user_id")
                expect(actual.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id",
                ]
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$userId": "user_id",
                ]
                verify(exactly: 0) {
                    listener.onUserUpdatedMock
                }
            }
        }

        describe("setDeviceId") {
            it("new") {
                sut.initialize(user: nil)
                let actual = sut.setDeviceId(deviceId: "device_id")
                expect(actual.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                verify(exactly: 1) {
                    listener.onUserUpdatedMock
                }
            }

            it("change") {
                sut.initialize(user: User.builder().deviceId("device_id").build())
                let actual = sut.setDeviceId(deviceId: "device_id_2")
                expect(actual.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                ]
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id_2",
                ]
                verify(exactly: 1) {
                    listener.onUserUpdatedMock
                }
            }

            it("same") {
                sut.initialize(user: User.builder().deviceId("device_id").build())
                let actual = sut.setDeviceId(deviceId: "device_id")
                expect(actual.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]
                verify(exactly: 0) {
                    listener.onUserUpdatedMock
                }
            }
        }

        describe("resetUser") {
            it("same") {
                sut.initialize(user: nil)
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]

                sut.resetUser()
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]
                verify(exactly: 0) {
                    listener.onUserUpdatedMock
                }
            }

            it("rest") {
                sut.initialize(user: User.builder().deviceId("device_id").build())
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "device_id",
                ]

                sut.resetUser()
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]
                verify(exactly: 1) {
                    listener.onUserUpdatedMock
                }
            }
        }

        describe("onChanged") {
            it("foreground - do nothing") {
                sut.onState(state: .foreground, timestamp: Date())
            }
            it("background") {
                expect(repository.getData(key: "user")).to(beNil())
                sut.onState(state: .background, timestamp: Date())
                expect(repository.getData(key: "user")).notTo(beNil())
            }
        }
    }
}
