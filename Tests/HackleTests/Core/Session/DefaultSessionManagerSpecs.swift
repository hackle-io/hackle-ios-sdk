import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class DefaultSessionManagerSpecs: QuickSpec {
    override class func spec() {

        func manager(
            persistCondition: HackleSessionPersistCondition = .alwaysNewSession,
            sessionTimeout: TimeInterval = 10,
            onForeground: Bool = false,
            onBackground: Bool = true,
            onApplicationStateChange: Bool = true,
            repository: KeyValueRepository = MemoryKeyValueRepository(),
            appStateManager: MockApplicationLifecycleManager = MockApplicationLifecycleManager(currentState: .foreground),
            _ listeners: SessionListener...
        ) -> DefaultSessionManager {
            let policy = HackleSessionPolicy.builder()
                .persistCondition(persistCondition)
                .timeoutCondition(
                    HackleSessionTimeoutCondition.builder()
                        .timeoutIntervalSeconds(sessionTimeout)
                        .onForeground(onForeground)
                        .onBackground(onBackground)
                        .onApplicationStateChange(onApplicationStateChange)
                        .build()
                )
                .build()

            let sut = DefaultSessionManager(
                userManager: MockUserManager(),
                keyValueRepository: repository,
                applicationLifecycleManager: appStateManager,
                sessionPolicy: policy
            )
            for listener in listeners {
                sut.addListener(listener: listener)
            }
            return sut
        }

        let user = User.builder().deviceId("device1").userId("A").build()

        it("requiredSession") {
            let sut = manager()
            expect(sut.requiredSession.id) == "0.ffffffff"
            sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
            expect(sut.requiredSession.id.hasPrefix("42000.")) == true
        }

        describe("initialize") {
            it("저장된 데이터가 있는 경우") {
                let repository = MemoryKeyValueRepository(dict: ["session_id": "42.ffffffff", "last_event_time": 42.0])
                let sut = manager(repository: repository)

                sut.initialize()

                expect(sut.currentSession?.id) == "42.ffffffff"
                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
            }

            it("저장된 데이터가 없는 경우") {
                let sut = manager(repository: MemoryKeyValueRepository())

                sut.initialize()

                expect(sut.currentSession).to(beNil())
                expect(sut.lastEventTime).to(beNil())
            }
        }

        it("startNewSession") {
            let repository = MemoryKeyValueRepository()
            let listener = SessionListenerStub()
            let sut = manager(repository: repository, listener)

            expect(sut.currentSession).to(beNil())
            expect(sut.lastEventTime).to(beNil())

            let user1 = User.builder().id("user1").build()
            let session1 = sut.startNewSession(oldUser: user1, newUser: user1, timestamp: Date(timeIntervalSince1970: 42))

            expect(session1.id.hasPrefix("42000.")) == true
            expect(sut.currentSession) == session1
            expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
            expect(listener.started.count) == 1
            expect(listener.started[0].0) == session1
            expect(listener.ended.count) == 0

            let user2 = User.builder().id("user2").build()
            let session2 = sut.startNewSession(oldUser: user1, newUser: user2, timestamp: Date(timeIntervalSince1970: 43))

            expect(session2.id.hasPrefix("43000.")) == true
            expect(sut.currentSession) == session2
            expect(sut.lastEventTime) == Date(timeIntervalSince1970: 43)
            expect(listener.started.count) == 2
            expect(listener.started[1].0) == session2
            expect(listener.started[1].1.id) == "user2"
            expect(listener.ended.count) == 1
            expect(listener.ended[0].0) == session1
            expect(repository.getString(key: "session_id")) == session2.id
            expect(repository.getDouble(key: "last_event_time")) == 43
        }

        describe("startNewSessionIfNeeded") {
            it("currentSession 이 없으면 새 세션을 시작한다") {
                let sut = manager()

                let session = sut.startNewSessionIfNeeded(
                    context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 42))
                )

                expect(session.id.starts(with: "42000.")) == true
                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
            }

            it("세션 만료 전이면 기존 세션을 리턴한다") {
                let sut = manager(sessionTimeout: 10, appStateManager: MockApplicationLifecycleManager(currentState: .background))

                let session1 = sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session2 = sut.startNewSessionIfNeeded(
                    context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 51))
                )

                expect(session1) == session2
                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 51)
            }

            it("세션이 만료됐으면 새로운 세션을 시작한다") {
                let listener = SessionListenerStub()
                let sut = manager(sessionTimeout: 10, appStateManager: MockApplicationLifecycleManager(currentState: .background), listener)

                let session1 = sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session2 = sut.startNewSessionIfNeeded(
                    context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 52))
                )

                expect(session1) != session2
                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 52)
                expect(listener.started.count) == 2
                expect(listener.started[0].0) == session1
                expect(listener.started[1].0) == session2
                expect(listener.ended.count) == 1
                expect(listener.ended[0].0) == session1
            }

            context("timeout flag 조합") {
                it("foreground + onForeground true + 만료 시 새 세션") {
                    let sut = manager(sessionTimeout: 10, onForeground: true,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .foreground))

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 52))
                    )

                    expect(session2) != session1
                }

                it("foreground + onForeground true + 미만료 시 기존 세션 유지") {
                    let sut = manager(sessionTimeout: 10, onForeground: true,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .foreground))

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 51))
                    )

                    expect(session2) == session1
                }

                it("foreground + onForeground false 이면 lastEventTime 만 갱신") {
                    let sut = manager(sessionTimeout: 10, onForeground: false,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .foreground))

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 52))
                    )

                    expect(session2) == session1
                    expect(sut.lastEventTime) == Date(timeIntervalSince1970: 52)
                }

                it("foreground + onForeground false 여도 식별자 변경 시 새 세션") {
                    let sut = manager(sessionTimeout: 10, onForeground: false,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .foreground))

                    let oldUser = User.builder().deviceId("d1").userId("A").build()
                    sut.startNewSession(oldUser: oldUser, newUser: oldUser, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let newUser = User.builder().deviceId("d1").userId("B").build()
                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(oldUser: oldUser, newUser: newUser, timestamp: Date(timeIntervalSince1970: 43))
                    )

                    expect(session2) != session1
                }

                it("background + onBackground true + 만료 시 새 세션") {
                    let sut = manager(sessionTimeout: 10, onBackground: true,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .background))

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 52))
                    )

                    expect(session2) != session1
                }

                it("background + onBackground true + 미만료 시 기존 세션 유지") {
                    let sut = manager(sessionTimeout: 10, onBackground: true,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .background))

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 51))
                    )

                    expect(session2) == session1
                }

                it("background + onBackground false + 만료 시에도 기존 세션 유지") {
                    let sut = manager(sessionTimeout: 10, onBackground: false,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .background))

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 52))
                    )

                    expect(session2) == session1
                }

                it("background + onBackground false 여도 식별자 변경 시 새 세션") {
                    let sut = manager(sessionTimeout: 10, onBackground: false,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .background))

                    let oldUser = User.builder().deviceId("d1").userId("A").build()
                    sut.startNewSession(oldUser: oldUser, newUser: oldUser, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let newUser = User.builder().deviceId("d1").userId("B").build()
                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(oldUser: oldUser, newUser: newUser, timestamp: Date(timeIntervalSince1970: 43))
                    )

                    expect(session2) != session1
                }

                it("onApplicationStateChange true + 만료 시 새 세션") {
                    let sut = manager(sessionTimeout: 10, onApplicationStateChange: true)

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 52), isApplicationStateChange: true)
                    )

                    expect(session2) != session1
                }

                it("onApplicationStateChange true + 미만료 시 기존 세션 유지") {
                    let sut = manager(sessionTimeout: 10, onApplicationStateChange: true)

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 51), isApplicationStateChange: true)
                    )

                    expect(session2) == session1
                }

                it("onApplicationStateChange false 이면 앱 상태 전환 시 타임아웃으로 만료되지 않는다") {
                    let sut = manager(sessionTimeout: 10, onApplicationStateChange: false)

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 52), isApplicationStateChange: true)
                    )

                    expect(session2) == session1
                }

                it("onApplicationStateChange false + onBackground true 이면 background 에서만 타임아웃") {
                    let sut = manager(sessionTimeout: 10, onBackground: true, onApplicationStateChange: false,
                                      appStateManager: MockApplicationLifecycleManager(currentState: .background))

                    sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                    let session1 = sut.currentSession!

                    // 앱 상태 전환 (isApplicationStateChange=true) → onApplicationStateChange=false이므로 만료 안됨
                    let session2 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 52), isApplicationStateChange: true)
                    )
                    expect(session2) == session1

                    // background 이벤트 (isApplicationStateChange=false) → onBackground=true이므로 만료됨
                    let session3 = sut.startNewSessionIfNeeded(
                        context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 62))
                    )
                    expect(session3) != session1
                }
            }
        }

        describe("통합 테스트") {
            it("onBackground false - 백그라운드 이벤트 후 포그라운드 전환 시 세션 재시작") {
                let appStateManager = MockApplicationLifecycleManager(currentState: .foreground)
                let sut = manager(sessionTimeout: 10, onBackground: false, appStateManager: appStateManager)

                sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                // background로 전환
                appStateManager.currentState = .background
                sut.onBackground(nil, timestamp: Date(timeIntervalSince1970: 43))

                // background 이벤트 (onBackground=false이므로 만료 안됨)
                let session2 = sut.startNewSessionIfNeeded(
                    context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 53))
                )
                expect(session2) == session1

                // foreground 전환 (onApplicationStateChange=true이고 timeout 경과이므로 만료됨)
                sut.onForeground(nil, timestamp: Date(timeIntervalSince1970: 64), isFromBackground: true)
                expect(sut.currentSession) != session1
            }

            it("onBackground true - 백그라운드 이벤트로 세션 재시작") {
                let appStateManager = MockApplicationLifecycleManager(currentState: .foreground)
                let sut = manager(sessionTimeout: 10, onBackground: true, appStateManager: appStateManager)

                sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                // background로 전환
                appStateManager.currentState = .background
                sut.onBackground(nil, timestamp: Date(timeIntervalSince1970: 43))

                // background 이벤트 (onBackground=true이므로 만료됨)
                let session2 = sut.startNewSessionIfNeeded(
                    context: SessionContext.of(user: user, timestamp: Date(timeIntervalSince1970: 53))
                )
                expect(session2) != session1
            }
        }

        describe("onForeground") {
            it("lastEventTime 이 없으면 새 세션을 시작한다") {
                let sut = manager()

                sut.onForeground(nil, timestamp: Date(timeIntervalSince1970: 42), isFromBackground: true)

                expect(sut.currentSession).toNot(beNil())
                expect(sut.currentSession!.id.hasPrefix("42000.")) == true
            }

            it("세션 만료 전이면 기존 세션을 유지한다") {
                let sut = manager(sessionTimeout: 10)

                sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                sut.onForeground(nil, timestamp: Date(timeIntervalSince1970: 51), isFromBackground: true)

                expect(sut.currentSession) == session1
            }

            it("세션이 만료됐으면 새 세션을 시작한다") {
                let sut = manager(sessionTimeout: 10)

                sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                sut.onForeground(nil, timestamp: Date(timeIntervalSince1970: 52), isFromBackground: true)

                expect(sut.currentSession) != session1
            }

            it("onApplicationStateChange false 이면 타임아웃으로 만료되지 않는다") {
                let sut = manager(sessionTimeout: 10, onApplicationStateChange: false)

                sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                sut.onForeground(nil, timestamp: Date(timeIntervalSince1970: 52), isFromBackground: true)

                expect(sut.currentSession) == session1
            }

            it("onApplicationStateChange false 여도 세션이 없으면 새 세션을 시작한다") {
                let sut = manager(sessionTimeout: 10, onApplicationStateChange: false)

                sut.onForeground(nil, timestamp: Date(timeIntervalSince1970: 42), isFromBackground: true)

                expect(sut.currentSession).toNot(beNil())
            }
        }

        describe("onBackground") {
            it("lastEventTime 을 업데이트한다") {
                let sut = manager()

                sut.onBackground(nil, timestamp: Date(timeIntervalSince1970: 42))

                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
            }

            it("현재 세션을 저장한다") {
                let repository = MemoryKeyValueRepository()
                let sut = manager(repository: repository)

                sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session = sut.currentSession!

                sut.onBackground(nil, timestamp: Date(timeIntervalSince1970: 43))

                expect(repository.getString(key: "session_id")) == session.id
            }

            it("현재 세션이 없으면 저장하지 않는다") {
                let repository = MemoryKeyValueRepository()
                let sut = manager(repository: repository)

                sut.onBackground(nil, timestamp: Date(timeIntervalSince1970: 42))

                expect(repository.getString(key: "session_id")).to(beNil())
            }
        }

        describe("onUserUpdated") {
            it("identifier 가 변경되지 않으면 세션을 유지한다") {
                let sut = manager()

                sut.startNewSession(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                sut.onUserUpdated(oldUser: user, newUser: user, timestamp: Date(timeIntervalSince1970: 43))

                expect(sut.currentSession) == session1
            }

            it("default policy 에서 identifier 가 변경되면 새 세션을 시작한다") {
                let sut = manager()

                let oldUser = User.builder().deviceId("d1").userId("A").build()
                sut.startNewSession(oldUser: oldUser, newUser: oldUser, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                let newUser = User.builder().deviceId("d1").userId("B").build()
                sut.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: Date(timeIntervalSince1970: 43))

                expect(sut.currentSession) != session1
            }

            it("custom policy 로 null → userId 시 세션을 유지한다") {
                let sut = manager(persistCondition: .nullToUserId)

                let oldUser = User.builder().deviceId("d1").build()
                sut.startNewSession(oldUser: oldUser, newUser: oldUser, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                let newUser = User.builder().deviceId("d1").userId("A").build()
                sut.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: Date(timeIntervalSince1970: 43))

                expect(sut.currentSession) == session1
            }

            it("identifier 가 동일하면 세션을 유지한다") {
                let sut = manager()

                let sameUser = User.builder().deviceId("d1").userId("A").build()
                sut.startNewSession(oldUser: sameUser, newUser: sameUser, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                sut.onUserUpdated(oldUser: sameUser, newUser: sameUser, timestamp: Date(timeIntervalSince1970: 43))

                expect(sut.currentSession) == session1
            }

            it("policy 가 유지를 결정해도 타임아웃이 만료되면 새 세션을 시작한다") {
                let sut = manager(persistCondition: .nullToUserId, sessionTimeout: 10,
                                  appStateManager: MockApplicationLifecycleManager(currentState: .background))

                let oldUser = User.builder().deviceId("d1").build()
                sut.startNewSession(oldUser: oldUser, newUser: oldUser, timestamp: Date(timeIntervalSince1970: 42))
                let session1 = sut.currentSession!

                let newUser = User.builder().deviceId("d1").userId("A").build()
                sut.onUserUpdated(oldUser: oldUser, newUser: newUser, timestamp: Date(timeIntervalSince1970: 52))

                // NULL_TO_USER_ID persist condition은 세션 유지를 원하지만, timeout 만료이므로 새 세션
                // 단, onUserUpdated는 isApplicationStateChange=false이므로 background의 onBackground flag(true)를 따름
                expect(sut.currentSession) != session1
            }
        }

        it("updateLastEventTime") {
            let repository = MemoryKeyValueRepository()
            let sut = manager(repository: repository)

            expect(sut.lastEventTime).to(beNil())
            sut.updateLastEventTime(timestamp: Date(timeIntervalSince1970: 42))
            expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
            expect(repository.getDouble(key: "last_event_time")) == 42.0
        }

        // MARK: - Persist Policy Tests

        describe("persistPolicy") {

            let nullToUserId: HackleSessionPersistCondition = .nullToUserId
            let userIdChange = UserIdChangePersistCondition()
            let userIdToNull = UserIdToNullPersistCondition()
            let deviceIdChange = DeviceIdChangePersistCondition()

            struct Scenario {
                let name: String
                let oldUser: User
                let newUser: User
            }

            let d1 = "device1"
            let d2 = "device2"

            let scenarios: [Scenario] = [
                Scenario(
                    name: "deviceId 동일, userId null → A",
                    oldUser: User.builder().deviceId(d1).build(),
                    newUser: User.builder().deviceId(d1).userId("A").build()
                ),
                Scenario(
                    name: "deviceId 동일, userId A → B",
                    oldUser: User.builder().deviceId(d1).userId("A").build(),
                    newUser: User.builder().deviceId(d1).userId("B").build()
                ),
                Scenario(
                    name: "deviceId 동일, userId A → null",
                    oldUser: User.builder().deviceId(d1).userId("A").build(),
                    newUser: User.builder().deviceId(d1).build()
                ),
                Scenario(
                    name: "deviceId 변경, userId 동일",
                    oldUser: User.builder().deviceId(d1).userId("A").build(),
                    newUser: User.builder().deviceId(d2).userId("A").build()
                ),
                Scenario(
                    name: "deviceId 변경, userId null → A",
                    oldUser: User.builder().deviceId(d1).build(),
                    newUser: User.builder().deviceId(d2).userId("A").build()
                ),
                Scenario(
                    name: "deviceId 변경, userId A → B",
                    oldUser: User.builder().deviceId(d1).userId("A").build(),
                    newUser: User.builder().deviceId(d2).userId("B").build()
                ),
                Scenario(
                    name: "deviceId 변경, userId A → null",
                    oldUser: User.builder().deviceId(d1).userId("A").build(),
                    newUser: User.builder().deviceId(d2).build()
                ),
            ]

            struct PolicyCase {
                let name: String
                let condition: HackleSessionPersistCondition
                // true = 세션 유지, false = 세션 만료
                let expected: [Bool]
            }

            let cases: [PolicyCase] = [
                // 1
                PolicyCase(
                    name: "Default",
                    condition: .alwaysNewSession,
                    expected: [false, false, false, false, false, false, false]
                ),
                // 2
                PolicyCase(
                    name: "NULL_TO_USER_ID",
                    condition: nullToUserId,
                    expected: [true, false, false, false, true, false, false]
                ),
                // 3
                PolicyCase(
                    name: "USER_ID_CHANGE",
                    condition: userIdChange,
                    expected: [false, true, false, false, false, true, false]
                ),
                // 4
                PolicyCase(
                    name: "USER_ID_TO_NULL",
                    condition: userIdToNull,
                    expected: [false, false, true, false, false, false, true]
                ),
                // 5
                PolicyCase(
                    name: "DEVICE_ID_CHANGE",
                    condition: deviceIdChange,
                    expected: [false, false, false, true, true, true, true]
                ),
                // 6
                PolicyCase(
                    name: "NULL_TO_USER_ID, USER_ID_CHANGE",
                    condition: CompositePersistCondition([nullToUserId, userIdChange]),
                    expected: [true, true, false, false, true, true, false]
                ),
                // 7
                PolicyCase(
                    name: "NULL_TO_USER_ID, USER_ID_TO_NULL",
                    condition: CompositePersistCondition([nullToUserId, userIdToNull]),
                    expected: [true, false, true, false, true, false, true]
                ),
                // 8
                PolicyCase(
                    name: "NULL_TO_USER_ID, DEVICE_ID_CHANGE",
                    condition: CompositePersistCondition([nullToUserId, deviceIdChange]),
                    expected: [true, false, false, true, true, true, true]
                ),
                // 9
                PolicyCase(
                    name: "USER_ID_CHANGE, USER_ID_TO_NULL",
                    condition: CompositePersistCondition([userIdChange, userIdToNull]),
                    expected: [false, true, true, false, false, true, true]
                ),
                // 10
                PolicyCase(
                    name: "USER_ID_CHANGE, DEVICE_ID_CHANGE",
                    condition: CompositePersistCondition([userIdChange, deviceIdChange]),
                    expected: [false, true, false, true, true, true, true]
                ),
                // 11
                PolicyCase(
                    name: "USER_ID_TO_NULL, DEVICE_ID_CHANGE",
                    condition: CompositePersistCondition([userIdToNull, deviceIdChange]),
                    expected: [false, false, true, true, true, true, true]
                ),
                // 12
                PolicyCase(
                    name: "NULL_TO_USER_ID, USER_ID_CHANGE, USER_ID_TO_NULL",
                    condition: CompositePersistCondition([nullToUserId, userIdChange, userIdToNull]),
                    expected: [true, true, true, false, true, true, true]
                ),
                // 13
                PolicyCase(
                    name: "NULL_TO_USER_ID, USER_ID_CHANGE, DEVICE_ID_CHANGE",
                    condition: CompositePersistCondition([nullToUserId, userIdChange, deviceIdChange]),
                    expected: [true, true, false, true, true, true, true]
                ),
                // 14
                PolicyCase(
                    name: "NULL_TO_USER_ID, USER_ID_TO_NULL, DEVICE_ID_CHANGE",
                    condition: CompositePersistCondition([nullToUserId, userIdToNull, deviceIdChange]),
                    expected: [true, false, true, true, true, true, true]
                ),
                // 15
                PolicyCase(
                    name: "USER_ID_CHANGE, USER_ID_TO_NULL, DEVICE_ID_CHANGE",
                    condition: CompositePersistCondition([userIdChange, userIdToNull, deviceIdChange]),
                    expected: [false, true, true, true, true, true, true]
                ),
                // 16
                PolicyCase(
                    name: "NULL_TO_USER_ID, USER_ID_CHANGE, USER_ID_TO_NULL, DEVICE_ID_CHANGE",
                    condition: CompositePersistCondition([nullToUserId, userIdChange, userIdToNull, deviceIdChange]),
                    expected: [true, true, true, true, true, true, true]
                ),
            ]

            for pCase in cases {
                describe(pCase.name) {
                    for (i, scenario) in scenarios.enumerated() {
                        let persist = pCase.expected[i]
                        it("\(scenario.name) → \(persist ? "세션 유지" : "세션 만료")") {
                            let sut = manager(persistCondition: pCase.condition)

                            let initialSession = sut.startNewSession(
                                oldUser: scenario.oldUser,
                                newUser: scenario.oldUser,
                                timestamp: Date(timeIntervalSince1970: 42)
                            )

                            let resultSession = sut.startNewSessionIfNeeded(
                                context: SessionContext.of(
                                    oldUser: scenario.oldUser,
                                    newUser: scenario.newUser,
                                    timestamp: Date(timeIntervalSince1970: 43)
                                )
                            )

                            if persist {
                                expect(resultSession) == initialSession
                            } else {
                                expect(resultSession) != initialSession
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Test Helpers

fileprivate class SessionListenerStub: SessionListener {

    var started = [(Session, User, Date)]()
    var ended = [(Session, User, Date)]()

    func onSessionStarted(session: Session, user: User, timestamp: Date) {
        started.append((session, user, timestamp))
    }

    func onSessionEnded(session: Session, user: User, timestamp: Date) {
        ended.append((session, user, timestamp))
    }
}

private class UserIdChangePersistCondition: HackleSessionPersistCondition {
    override func shouldPersist(oldUser: User, newUser: User) -> Bool {
        oldUser.userId != nil && newUser.userId != nil && oldUser.userId != newUser.userId
    }
}

private class UserIdToNullPersistCondition: HackleSessionPersistCondition {
    override func shouldPersist(oldUser: User, newUser: User) -> Bool {
        oldUser.userId != nil && newUser.userId == nil
    }
}

private class DeviceIdChangePersistCondition: HackleSessionPersistCondition {
    override func shouldPersist(oldUser: User, newUser: User) -> Bool {
        oldUser.deviceId != newUser.deviceId
    }
}

private class CompositePersistCondition: HackleSessionPersistCondition {
    private let conditions: [HackleSessionPersistCondition]

    init(_ conditions: [HackleSessionPersistCondition]) {
        self.conditions = conditions
        super.init()
    }

    override func shouldPersist(oldUser: User, newUser: User) -> Bool {
        conditions.contains { $0.shouldPersist(oldUser: oldUser, newUser: newUser) }
    }
}
