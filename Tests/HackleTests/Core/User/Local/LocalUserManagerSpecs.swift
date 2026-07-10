import Foundation
import Quick
import Nimble
@testable import Hackle


class LocalUserManagerSpecs: AsyncSpec {
    override class func spec() {
        var repository: KeyValueRepository!
        var cohortFetcher: MockUserCohortFetcher!
        var targetFetcher: MockUserTargetFetcher!
        var clock: Clock!
        var device: Device!
        var bundleInfo: BundleInfo!
        var sut: LocalUserManager!

        var listener: MockUserListener!

        beforeEach {
            repository = MemoryKeyValueRepository()
            cohortFetcher = MockUserCohortFetcher()
            targetFetcher = MockUserTargetFetcher()
            clock = FixedClock(date: Date(timeIntervalSince1970: 42))
            let deviceImpl = DeviceImpl(deviceId: "hackle_device_id")
            await MainActor.run { deviceImpl.initialize() }
            device = deviceImpl
            bundleInfo = BundleInfoImpl()
            sut = LocalUserManager(device: device, bundleInfo: bundleInfo, repository: UserRepository(repository: repository), cohortFetcher: cohortFetcher, targetFetcher: targetFetcher, clock: clock)
            every(cohortFetcher.fetchMock).answers { _ in UserCohorts() }
            every(targetFetcher.fetchMock).answers { _ in UserTargetEvents() }
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

            it("when failed to load user then init with default user") {
                repository.putData(key: "user", value: "invalid json".data(using: .utf8)!)
                sut.initialize(user: nil)
                let user = sut.currentUser
                expect(user.resolvedIdentifiers) == ["$id": "hackle_device_id", "$deviceId": "hackle_device_id"]
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

        describe("hackleUser") {
            it("currentUser") {
                sut.initialize(user: User.builder().id("init_id").deviceId("init_device_id").userId("init_user_id").build())
                let actual = sut.hackleUser()
                expect(actual.identifiers) == [
                    "$id": "init_id",
                    "$deviceId": "init_device_id",
                    "$userId": "init_user_id",
                    "$hackleDeviceId": "hackle_device_id"
                ]
            }

            it("inputUser") {
                sut.initialize(user: nil)
                let actual = sut.hackleUser(user: User.builder().id("input_id").build())
                expect(actual.identifiers) == [
                    "$id": "input_id",
                    "$deviceId": "hackle_device_id",
                    "$hackleDeviceId": "hackle_device_id"
                ]
            }
        }

        describe("hackleUser(user:) merge") {
            it("merge with current context") {
                // given
                let userCohorts = UserCohorts.builder()
                    .put(cohort: UserCohort(identifier: Identifier(type: "$id", value: "id"), cohorts: [Cohort(id: 42)]))
                    .build()
                let userTargetEvents = UserTargetEvents.builder()
                    .put(targetEvent: TargetEvent(
                        eventKey: "purchase",
                        stats: [
                            TargetEvent.Stat(
                                date: 1737361789000,
                                count: 10)
                        ],
                        property: TargetEvent.Property(
                            key: "product_name",
                            type: .eventProperty,
                            value: HackleValue.string("shampo")
                        )
                    ))
                    .build()
                every(cohortFetcher.fetchMock).answers { _ in UserCohorts.Builder(cohorts: userCohorts).build() }
                every(targetFetcher.fetchMock).answers { _ in UserTargetEvents.Builder(targetEvents: userTargetEvents).build() }

                // when
                sut.initialize(user: User.builder().id("id").property("a", "a").build())
                await awaitCompletion {
                    try? await sut.sync()
                    let hackleUser = sut.hackleUser(user: User.builder().id("id").userId("user_id").property("b", "b").build())
                    
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
            }

            it("full") {
                let hackleUser = sut.hackleUser(user: User.builder()
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
                let hackleUser = sut.hackleUser(user: User.builder().build())
                expect(hackleUser.identifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                    "$hackleDeviceId": "hackle_device_id"
                ]
            }

            it("hackle properties") {
                let hackleUser = sut.hackleUser(user: User.builder().build())
                expect(hackleUser.hackleProperties.count) > 0
            }

            it("hackle properties contains device properties") {
                let hackleUser = sut.hackleUser(user: User.builder().build())

                // Device properties
                expect(hackleUser.hackleProperties["platform"] as? String) == "iOS"
                expect(hackleUser.hackleProperties["osName"] as? String).notTo(beNil())
                expect(hackleUser.hackleProperties["osVersion"] as? String).notTo(beNil())
                expect(hackleUser.hackleProperties["deviceModel"] as? String).notTo(beNil())
                expect(hackleUser.hackleProperties["deviceType"] as? String).notTo(beNil())
                expect(hackleUser.hackleProperties["deviceBrand"] as? String) == "Apple"
                expect(hackleUser.hackleProperties["deviceManufacturer"] as? String) == "Apple"
                expect(hackleUser.hackleProperties["locale"] as? String).notTo(beNil())
                expect(hackleUser.hackleProperties["language"] as? String).notTo(beNil())
                expect(hackleUser.hackleProperties["timeZone"] as? String).notTo(beNil())
                expect(hackleUser.hackleProperties["screenWidth"] as? Int).notTo(beNil())
                expect(hackleUser.hackleProperties["screenHeight"] as? Int).notTo(beNil())
                expect(hackleUser.hackleProperties["isApp"] as? Bool) == true
            }

            it("hackle properties contains bundle info properties") {
                let hackleUser = sut.hackleUser(user: User.builder().build())

                // BundleInfo properties
                expect(hackleUser.hackleProperties["packageName"]).notTo(beNil())
                expect(hackleUser.hackleProperties["versionName"]).notTo(beNil())
                expect(hackleUser.hackleProperties["versionCode"]).notTo(beNil())
            }

            it("hackle properties merges device and bundle info") {
                let hackleUser = sut.hackleUser(user: User.builder().build())

                // Should contain both device and bundle info properties
                let hasDeviceProperty = hackleUser.hackleProperties["platform"] != nil
                let hasBundleProperty = hackleUser.hackleProperties["packageName"] != nil

                expect(hasDeviceProperty) == true
                expect(hasBundleProperty) == true
                expect(hackleUser.hackleProperties.count) >= 16 // At least device (13) + bundle (3) properties
            }
        }

        describe("sync") {
            it("update userCohorts") {
                let userCohorts = UserCohorts.builder()
                    .put(cohort: UserCohort(identifier: Identifier(type: "$id", value: "hackle_device_id"), cohorts: [Cohort(id: 42)]))
                    .build()
                let userTargetEvents = UserTargetEvents.builder()
                    .put(targetEvent: TargetEvent(
                        eventKey: "purchase",
                        stats: [
                            TargetEvent.Stat(
                                date: 1737361789000,
                                count: 10)
                        ],
                        property: TargetEvent.Property(
                            key: "product_name",
                            type: .eventProperty,
                            value: HackleValue.string("shampo")
                        )
                    ))
                    .build()
                every(cohortFetcher.fetchMock).answers { _ in UserCohorts.Builder(cohorts: userCohorts).build() }
                every(targetFetcher.fetchMock).answers { _ in UserTargetEvents.Builder(targetEvents: userTargetEvents).build() }

                sut.initialize(user: nil)
                expect(sut.hackleUser().cohorts) == []
                await awaitCompletion {
                    try? await sut.sync()
                    expect(sut.hackleUser().cohorts) == [Cohort(id: 42)]
                }
            }
        }
        
        describe("sync") {
            it("when sync target event, overwrite") {
                let targetEvent = TargetEvent(
                    eventKey: "purchase",
                    stats: [
                        TargetEvent.Stat(
                            date: 1737361789000,
                            count: 10)
                    ],
                    property: TargetEvent.Property(
                        key: "product_name",
                        type: .eventProperty,
                        value: HackleValue.string("shampo")
                    )
                )
                let targetEvent2 = TargetEvent(
                    eventKey: "login",
                    stats: [
                        TargetEvent.Stat(
                            date: 1737361789000,
                            count: 10)
                    ],
                    property: nil
                )
                let targetEvents = [targetEvent, targetEvent2]
                
                
                // given
                every(targetFetcher.fetchMock).answers { _ in UserTargetEvents.Builder(targetEvents: UserTargetEvents.builder().putAll(targetEvents: targetEvents).build()).build() }
                sut.initialize(user: nil)
                await awaitCompletion {
                    try? await sut.sync()
                    expect(sut.hackleUser().targetEvents) == targetEvents
                    expect(sut.hackleUser().targetEvents.count) == 2
                }
                
                let newTargetEvents = [targetEvent]
                every(targetFetcher.fetchMock).answers { _ in UserTargetEvents.Builder(targetEvents: UserTargetEvents.builder().putAll(targetEvents: newTargetEvents).build()).build() }
                await awaitCompletion {
                    try? await sut.sync()
                    expect(sut.hackleUser().targetEvents) == newTargetEvents
                    expect(sut.hackleUser().targetEvents.count) == 1
                }
            }
        }

        // Task 11: syncIfNeeded(updated:)가 private으로 바뀌어 mutator가 내부에서 흡수한다.
        // BEFORE(구 계약)에는 Updated(previous:current:)를 합성해 syncIfNeeded를 직접 호출/검증했으나,
        // AFTER(신 계약)에서는 mutator(setUserId/setDeviceId/setUser/resetUser) 호출 후 cohort/targetEvent
        // fetch 여부로 간접 검증한다. hasNewIdentifiers(추가된 식별자 유무 → cohort)와
        // identifierEquals(userId+deviceId 동일 여부 → targetEvent)의 분기를 각각 대표 케이스로 커버한다.
        describe("mutator 호출에 따른 cohort/targetEvent 동기화") {
            it("변경이 없으면 cohort와 targetEvent 모두 동기화하지 않는다") {
                sut.initialize(user: User.builder().userId("user_a").deviceId("device_a").build())

                await sut.setUserId(userId: "user_a") // 동일 값 재설정

                verify(exactly: 0) {
                    cohortFetcher.fetchMock
                }
                verify(exactly: 0) {
                    targetFetcher.fetchMock
                }
            }

            it("userId가 새로운 값으로 변경되면 cohort와 targetEvent를 모두 동기화한다") {
                sut.initialize(user: User.builder().userId("user_a").build())

                await sut.setUserId(userId: "user_b")

                expect(sut.currentUser.userId) == "user_b"
                verify(exactly: 1) {
                    cohortFetcher.fetchMock
                }
                verify(exactly: 1) {
                    targetFetcher.fetchMock
                }
            }

            it("userId가 제거되면(새 식별자 없음) targetEvent만 동기화한다") {
                sut.initialize(user: User.builder().userId("user_a").build())

                await sut.setUserId(userId: nil)

                expect(sut.currentUser.userId).to(beNil())
                verify(exactly: 0) {
                    cohortFetcher.fetchMock
                }
                verify(exactly: 1) {
                    targetFetcher.fetchMock
                }
            }

            it("deviceId가 새로운 값으로 변경되면 cohort와 targetEvent를 모두 동기화한다") {
                sut.initialize(user: User.builder().deviceId("device_a").build())

                await sut.setDeviceId(deviceId: "device_b")

                expect(sut.currentUser.deviceId) == "device_b"
                verify(exactly: 1) {
                    cohortFetcher.fetchMock
                }
                verify(exactly: 1) {
                    targetFetcher.fetchMock
                }
            }

            it("deviceId를 동일한 값으로 재설정하면 아무것도 동기화하지 않는다") {
                sut.initialize(user: User.builder().deviceId("device_a").build())

                await sut.setDeviceId(deviceId: "device_a")

                verify(exactly: 0) {
                    cohortFetcher.fetchMock
                }
                verify(exactly: 0) {
                    targetFetcher.fetchMock
                }
            }

            it("setUser로 커스텀 식별자만 변경되면(userId/deviceId 동일) cohort만 동기화한다") {
                sut.initialize(user: User.builder().deviceId("device_a").identifier("custom", "custom_id").build())

                await sut.setUser(user: User.builder().deviceId("device_a").identifier("custom", "new_custom_id").build())

                verify(exactly: 1) {
                    cohortFetcher.fetchMock
                }
                verify(exactly: 0) {
                    targetFetcher.fetchMock
                }
            }

            it("resetUser로 userId가 제거되면(새 식별자 없음) targetEvent만 동기화한다") {
                sut.initialize(user: User.builder().userId("user_x").build())

                await sut.resetUser()

                expect(sut.currentUser.userId).to(beNil())
                verify(exactly: 0) {
                    cohortFetcher.fetchMock
                }
                verify(exactly: 1) {
                    targetFetcher.fetchMock
                }
            }
        }

        describe("setUser") {
            it("decorate hackleDeviceId") {
                await sut.setUser(user: User.builder().build())
                expect(sut.currentUser.resolvedIdentifiers) == [
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

                await sut.setUser(user: User.builder().deviceId("device_id").build())
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

                await sut.setUser(user: User.builder().deviceId("device_id").userId("user_id").build())
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

                await sut.setUser(user: User.builder().deviceId("device_id_2").build())
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

                await sut.setUser(user: User.builder().deviceId("device_id").userId("user_id").build())
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

                await sut.setUser(user: User.builder().deviceId("device_id_2").userId("user_id").build())
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

                await sut.setUser(user: User.builder().deviceId("device_id").build())
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

                await sut.setUser(user: User.builder().deviceId("device_id_2").build())
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

                await sut.setUser(user: User.builder().deviceId("device_id_2").userId("user_id").build())
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

                await sut.setUser(user: User.builder().deviceId("device_id").userId("user_id_2").build())
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
                every(cohortFetcher.fetchMock).answers { user in UserCohorts.Builder(cohorts: userCohorts).build() }

                sut.initialize(user: User.builder().deviceId("device_id").build())
                await awaitCompletion {
                    try? await sut.sync()
                    expect(sut.currentUser.resolvedIdentifiers) == [
                        "$id": "hackle_device_id",
                        "$deviceId": "device_id",
                    ]
                    expect(sut.hackleUser(user: sut.currentUser).cohorts) == [Cohort(id: 42)]
                }
            }
            
            it("update target event") {
                let userTargetEvents = UserTargetEvents.builder()
                    .put(targetEvent: TargetEvent(
                        eventKey: "purchase",
                        stats: [
                            TargetEvent.Stat(
                                date: 1737361789000,
                                count: 10)
                        ],
                        property: TargetEvent.Property(
                            key: "product_name",
                            type: .eventProperty,
                            value: HackleValue.string("shampo")
                        )
                    ))
                    .build()
                every(targetFetcher.fetchMock).answers { user in UserTargetEvents.Builder(targetEvents: userTargetEvents).build() }

                sut.initialize(user: nil)
                await awaitCompletion {
                    try? await sut.sync()
                    expect(sut.hackleUser().targetEvents.count) == 1
                    expect(sut.hackleUser().targetEvents[0].eventKey) == "purchase"
                    expect(sut.hackleUser().targetEvents[0].property?.key) == "product_name"
                }
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
                await sut.updateProperties(operations: operations)
                expect(sut.currentUser.properties["a"] as? Double) == 42.0
                expect(sut.currentUser.properties["c"] as? [String]) == ["cc"]
                expect(sut.currentUser.properties["d"] as? String) == "d"
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
                await sut.updateProperties(operations: operations)

                expect(sut.currentUser.properties["a"] as? Double) == 84.0
                expect(sut.currentUser.properties["b"] as? String) == "b"
                expect(sut.currentUser.properties["c"] as? [String]) == ["c", "cc"]
                expect(sut.currentUser.properties["d"] as? String) == "d"
            }
        }

        describe("setUserId") {
            it("new") {
                sut.initialize(user: nil)
                await sut.setUserId(userId: "user_id")
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

                await sut.setUserId(userId: nil)
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

                await sut.setUserId(userId: "user_id_2")
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

                await sut.setUserId(userId: "user_id")
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
                await sut.setDeviceId(deviceId: "device_id")
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
                await sut.setDeviceId(deviceId: "device_id_2")
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
                await sut.setDeviceId(deviceId: "device_id")
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

                await sut.resetUser()
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

                await sut.resetUser()
                expect(sut.currentUser.resolvedIdentifiers) == [
                    "$id": "hackle_device_id",
                    "$deviceId": "hackle_device_id",
                ]
                verify(exactly: 1) {
                    listener.onUserUpdatedMock
                }
            }
        }

        describe("onPropertyOperations") {
            it("updateProperties 시 변경 전 user와 operations를 발행한다") {
                sut.initialize(user: User.builder().userId("user_id").properties(["a": 1]).build())
                let operations = PropertyOperations.builder().set("age", 42).build()

                await sut.updateProperties(operations: operations)

                verify(exactly: 1) {
                    listener.onPropertyOperationsMock
                }
                let (user, publishedOperations, timestamp) = listener.onPropertyOperationsMock.firstInvokation().arguments
                expect(user.userId) == "user_id"
                expect(user.properties["age"]).to(beNil())
                expect(publishedOperations.asDictionary()[.set] as? [String: Int]) == ["age": 42]
                expect(timestamp) == Date(timeIntervalSince1970: 42) // clock.now()
                verify(exactly: 0) {
                    listener.onUserUpdatedMock // 식별자 불변 — onUserUpdated 미발행
                }
            }

            it("resetUser 시 변경 후(default) user와 clearAll을 발행한다") {
                sut.initialize(user: User.builder().userId("user_id").build())

                await sut.resetUser()

                verify(exactly: 1) {
                    listener.onPropertyOperationsMock
                }
                let (user, operations, _) = listener.onPropertyOperationsMock.firstInvokation().arguments
                expect(user.userId).to(beNil())
                expect(operations.contains(.clearAll)) == true
            }

            it("setUser/setUserId/setDeviceId 시에는 발행하지 않는다") {
                sut.initialize(user: nil)
                await sut.setUser(user: User.builder().userId("a").build())
                await sut.setUserId(userId: "b")
                await sut.setDeviceId(deviceId: "c")
                verify(exactly: 0) {
                    listener.onPropertyOperationsMock
                }
            }
        }

        describe("onChanged") {
            it("foreground - do nothing") {
                sut.onForeground(nil, timestamp: Date(), isFromBackground: true)
            }
            it("background") {
                expect(repository.getData(key: "user")).to(beNil())
                sut.onBackground(nil, timestamp: Date())
                expect(repository.getData(key: "user")).notTo(beNil())
            }
        }

        // setUser -> changeUser -> SessionManager -> SessionEventTracker -> hackleUser(user:) 재진입 체인.
        // 비재진입 lock이면 deadlock한다.
        describe("re-entrant lock") {
            it("listener가 onUserUpdated에서 hackleUser를 재호출해도 deadlock 없이 완료된다") {
                let reentrant = ReentrantUserListener(userManager: sut)
                sut.addListener(listener: reentrant)
                sut.initialize(user: nil)

                // setUser(async)의 mutation은 recursiveLock.lock { } 내부에서 여전히 동기적으로 일어난다(첫 await는
                // syncIfNeeded 이전이 아니라 그 호출 자체이므로, lock 재진입 체인은 async 승격 이전과 동일하게 검증 가능).
                let done = DispatchSemaphore(value: 0)
                DispatchQueue.global().async {
                    Task {
                        await sut.setUser(user: User.builder().userId("user_id").build())
                        done.signal()
                    }
                }

                expect(done.wait(timeout: .now() + 3)) == DispatchTimeoutResult.success
                expect(reentrant.reentrantUser?.identifiers["$userId"]) == "user_id"
            }
        }
    }
}

// onUserUpdated 시점에 hackleUser(user:)를 재호출해 lock 재진입을 유발하는 테스트 전용 listener.
fileprivate class ReentrantUserListener: UserListener {
    private weak var userManager: LocalUserManager?
    private(set) var reentrantUser: HackleUser?

    init(userManager: LocalUserManager) {
        self.userManager = userManager
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        reentrantUser = userManager?.hackleUser(user: newUser)
    }

    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {
        // nothing to do
    }
}
