import Foundation
@testable import Hackle
import Nimble
import Quick

class HackleAppSpecs: QuickSpec {
    override class func spec() {
        var core: MockHackleCore!
        var eventQueue: DispatchQueue!
        var synchronizer: MockSynchronizer!
        var platformManager: PlatformManager!
        var userManager: MockUserManager!
        var workspaceManager: WorkspaceConfigManager!
        var notificationManager: MockNotificationManager!
        var sessionManager: MockSessionManager!
        var screenManager: MockScreeManager!
        var eventProcessor: MockUserEventProcessor!
        var pushTokenRegistry = DefaultPushTokenRegistry()
        var userExplorer: HackleUserExplorer!
        var inAppMessageUI: HackleInAppMessageUI!

        var sut: HackleApp!

        beforeEach {
            Metrics.clear()
            core = MockHackleCore()
            eventQueue = DispatchQueue(label: "io.hackle.EventQueue", qos: .utility)
            synchronizer = MockSynchronizer()
            userManager = MockUserManager()
            workspaceManager = WorkspaceConfigManager(
                httpWorkspaceConfigFetcher: MockHttpWorkspaceConfigFetcher(returns: []),
                repository: MockWorkspaceConfigRepository()
            )
            let globalRepository = MemoryKeyValueRepository()
            globalRepository.putString(key: "hackle_device_id", value: "test_device_id")
            platformManager = PlatformManager(keyValueRepository: globalRepository)
            notificationManager = MockNotificationManager()
            sessionManager = MockSessionManager()
            screenManager = MockScreeManager()
            eventProcessor = MockUserEventProcessor()
            pushTokenRegistry = DefaultPushTokenRegistry()
            userExplorer = DefaultHackleUserExplorer(
                core: core,
                userManager: userManager,
                pushTokenManager: MockPushTokenManager(),
                abTestOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                featureFlagOverrideStorage: DefaultExperimentManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                devToolsAPI: MockDevToolsAPI()
            )
            inAppMessageUI = makeInAppMessageUI(core: core)
            let throttler = DefaultThrottler(limiter: ScopingThrottleLimiter(interval: 10, limit: 1, clock: SystemClock.shared))
            let built = makeHackleApp(
                core: core,
                coreQueue: eventQueue,
                synchronizer: synchronizer,
                userManager: userManager,
                workspaceManager: workspaceManager,
                sessionManager: sessionManager,
                screenManager: screenManager,
                eventProcessor: eventProcessor,
                pushTokenRegistry: pushTokenRegistry,
                notificationManager: notificationManager,
                platformManager: platformManager,
                userExplorer: userExplorer,
                inAppMessageUI: inAppMessageUI,
                throttler: throttler
            )
            sut = built.sut
        }

        it("deviceId") {
            expect(sut.deviceId) == "test_device_id"
        }

        it("sessionId") {
            sessionManager.requiredSession = Session(id: "42")
            expect(sut.sessionId) == "42"
        }

        it("user") {
            let user = User.builder().id("42").build()
            userManager.currentUser = user
            expect(sut.user).to(beIdenticalTo(user))
        }

        it("showUserExplorer") {
            sut.showUserExplorer()
        }

        it("showUserExplorer는 REMOTE 모드에서 무시된다") {
            let registry = CumulativeMetricRegistry()
            Metrics.addRegistry(registry: registry)
            let throttler = DefaultThrottler(limiter: ScopingThrottleLimiter(interval: 10, limit: 1, clock: SystemClock.shared))

            let built = makeHackleApp(
                core: core,
                evaluationMode: .remote,
                coreQueue: eventQueue,
                synchronizer: synchronizer,
                userManager: userManager,
                workspaceManager: workspaceManager,
                sessionManager: sessionManager,
                screenManager: screenManager,
                eventProcessor: eventProcessor,
                pushTokenRegistry: pushTokenRegistry,
                notificationManager: notificationManager,
                platformManager: platformManager,
                userExplorer: userExplorer,
                inAppMessageUI: inAppMessageUI,
                throttler: throttler
            )

            built.sut.showUserExplorer()

            expect(registry.counter(name: "user.explorer.show").count()) == 0
        }

        it("hideUserExplorer") {
            sut.hideUserExplorer()
        }

        describe("setUser") {
            it("set and sync") {
                let user = User.builder().id("42").build()
                waitUntil { done in
                    sut.setUser(user: user) {
                        done()
                    }
                }
                // setUserMock 호출 완료(waitUntil로 대기)가 곧 update+sync 완료를 의미한다.
                verify(exactly: 1) {
                    userManager.setUserMock
                }
                expect(userManager.setUserMock.firstInvokation().arguments).to(beIdenticalTo(user))
            }

            it("completion") {
                var count = 0
                let user = User.builder().id("42").build()
                waitUntil { done in
                    sut.setUser(user: user) {
                        count += 1
                        done()
                    }
                }
                expect(count) == 1
            }

            // 동기 프리픽스 회귀 가드: HackleAppCore.setUser는 userManager.setUser(user:)를 forward하고,
            // mutation은 userManager 내부에서 동기적으로 끝난다. 따라서 completion(네트워크 sync)을 기다리지 않아도
            // sut.setUser 반환 즉시 유저 갱신이 보인다.
            // 구 형태(`Task { await userManager.setUser }`)에서는 mutation이 Task로 지연되어 이 단언이 깨진다.
            it("setUser 반환 시점에 유저 갱신이 이미 완료된다 (동기 프리픽스)") {
                let user = User.builder().id("sync-prefix").build()
                sut.setUser(user: user, completion: {})
                // completion 대기 없이 즉시 확인 — mutation은 동기 프리픽스
                expect(userManager.currentUser.id) == "sync-prefix"
            }
        }

        describe("setUserId") {
            it("set and sync") {
                waitUntil { done in
                    sut.setUserId(userId: "user_id") {
                        done()
                    }
                }
                verify(exactly: 1) {
                    userManager.setUserIdMock
                }
                expect(userManager.setUserIdMock.firstInvokation().arguments) == "user_id"
            }

            it("completion") {
                var count = 0
                waitUntil { done in
                    sut.setUserId(userId: "user_id") {
                        count += 1
                        done()
                    }
                }
                expect(count) == 1
            }
        }

        describe("setDeviceId") {
            it("set and sync") {
                waitUntil { done in
                    sut.setDeviceId(deviceId: "device_id") {
                        done()
                    }
                }
                verify(exactly: 1) {
                    userManager.setDeviceIdMock
                }
                expect(userManager.setDeviceIdMock.firstInvokation().arguments) == "device_id"
            }

            it("completion") {
                var count = 0
                waitUntil { done in
                    sut.setDeviceId(deviceId: "device_id") {
                        count += 1
                        done()
                    }
                }
                expect(count) == 1
            }
        }

        describe("resetUser") {
            it("reset") {
                waitUntil { done in
                    sut.resetUser {
                        done()
                    }
                }
                verify(exactly: 1) {
                    userManager.resetUserMock
                }
                verify(exactly: 0) {
                    core.trackMock
                }
            }
            it("completion") {
                var count = 0
                waitUntil { done in
                    sut.resetUser {
                        count += 1
                        done()
                    }
                }
                expect(count) == 1
            }
        }

        describe("setUserProperty") {
            it("update properties") {
                // updateUserProperties가 Task<Void, Never>를 반환하므로 completion은 Task 완료 후
                // completionQueue로 재디스패치된다. mutator 호출도 completion 이후에만 보장된다.
                waitUntil { done in
                    sut.setUserProperty(key: "age", value: 42) {
                        done()
                    }
                }
                verify(exactly: 1) {
                    userManager.updatePropertiesMock
                }
                verify(exactly: 0) {
                    core.trackMock
                }
                verify(exactly: 0) {
                    eventProcessor.flushMock
                }
                expect(userManager.updatePropertiesMock.firstInvokation().arguments.asDictionary()[.set] as? [String: Int]) == ["age": 42]
            }

            it("completion") {
                var count = 0
                waitUntil { done in
                    sut.setUserProperty(key: "age", value: 42) {
                        count += 1
                        done()
                    }
                }
                expect(count) == 1
            }
        }

        describe("updateUserProperties") {
            it("update properties") {
                waitUntil { done in
                    sut.updateUserProperties(operations: PropertyOperations.builder().set("age", 42).build()) {
                        done()
                    }
                }
                verify(exactly: 1) {
                    userManager.updatePropertiesMock
                }
                verify(exactly: 0) {
                    core.trackMock
                }
                verify(exactly: 0) {
                    eventProcessor.flushMock
                }
            }

            it("completion") {
                var count = 0
                waitUntil { done in
                    sut.updateUserProperties(operations: PropertyOperations.builder().set("age", 42).build()) {
                        count += 1
                        done()
                    }
                }
                expect(count) == 1
            }

            it("updateUserProperties completion은 Task 완료 후 비동기로 호출된다 (동기 인라인 계약 소실)") {
                var called = false
                waitUntil { done in
                    sut.updateUserProperties(operations: PropertyOperations.builder().set("k", "v").build()) {
                        called = true
                        done()
                    }
                }
                expect(called) == true
            }
        }

        describe("marketing property") {
            it("setPushToken") {
                let deviceToken = "token".data(using: .utf8)!
                sut.setPushToken(deviceToken)
                expect(pushTokenRegistry.registeredToken()).notTo(beNil())
            }

            it("setPhoneNumber") {
                var count = 0
                waitUntil(timeout: .seconds(2)) { done in
                    sut.setPhoneNumber(phoneNumber: "+821012345678") {
                        count += 1
                        done()
                    }
                }
                expect(count) == 1
            }

            it("unsetPhoneNumber") {
                var count = 0
                waitUntil(timeout: .seconds(2)) { done in
                    sut.unsetPhoneNumber {
                        count += 1
                        done()
                    }
                }
                expect(count) == 1
            }
        }

        describe("experiment") {
            it("variation") {
                // given
                let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                every(userManager.hackleUserMock).returns(hackleUser)

                let decision = Decision.of(experiment: nil, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                every(core.experimentMock).returns(decision)

                // when
                let actual = sut.variation(experimentKey: 42)

                // then
                expect(actual) == "B"
                expect(userManager.hackleUserMock.firstInvokation().arguments.0).to(beIdenticalTo(userManager.currentUser))
            }

            describe("variationDetail") {
                it("success") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.hackleUserMock).returns(hackleUser)

                    let decision = Decision.of(experiment: nil, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                    every(core.experimentMock).returns(decision)

                    // when
                    let actual = sut.variationDetail(experimentKey: 42)

                    // then
                    expect(actual).to(beIdenticalTo(decision))
                    expect(userManager.hackleUserMock.firstInvokation().arguments.0).to(beIdenticalTo(userManager.currentUser))
                }

                it("when core throws then return control variation") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.hackleUserMock).returns(hackleUser)

                    every(core.experimentMock).willThrow(HackleError.error("fail"))

                    // when
                    let actual = sut.variationDetail(experimentKey: 42)

                    // then
                    expect(actual.variation) == "A"
                    expect(actual.reason) == DecisionReason.EXCEPTION
                    expect(userManager.hackleUserMock.firstInvokation().arguments.0).to(beIdenticalTo(userManager.currentUser))
                }
            }

            describe("allVariationDetailsInternal") {
                it("success") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.hackleUserMock).returns(hackleUser)

                    let experiment = MockExperiment(id: 1, key: 42)
                    let decision = Decision.of(experiment: experiment, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                    let decisions = [(experiment, decision)]
                    every(core.experimentsMock).returns(decisions)

                    // when
                    let actual = sut.allVariationDetails()

                    // then
                    expect(actual[42]).to(beIdenticalTo(decision))
                    expect(userManager.hackleUserMock.firstInvokation().arguments.0).to(beIdenticalTo(userManager.currentUser))
                }

                it("when core throws then return empty decisions") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.hackleUserMock).returns(hackleUser)

                    every(core.experimentsMock).willThrow(HackleError.error("fail"))

                    // when
                    let actual = sut.allVariationDetails()

                    // then
                    expect(actual.count) == 0
                    expect(userManager.hackleUserMock.firstInvokation().arguments.0).to(beIdenticalTo(userManager.currentUser))
                }
            }
        }

        describe("feature flag") {
            it("isFeatureOn") {
                // given
                let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                every(userManager.hackleUserMock).returns(hackleUser)

                let decision = FeatureFlagDecision.on(featureFlag: nil, reason: DecisionReason.DEFAULT_RULE)
                every(core.featureFlagMock).returns(decision)

                // when
                let actual = sut.isFeatureOn(featureKey: 42)

                // then
                expect(actual) == true
                expect(userManager.hackleUserMock.firstInvokation().arguments.0).to(beIdenticalTo(userManager.currentUser))
            }

            describe("featureFlagDetail") {
                it("success") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.hackleUserMock).returns(hackleUser)

                    let decision = FeatureFlagDecision.on(featureFlag: nil, reason: DecisionReason.DEFAULT_RULE)
                    every(core.featureFlagMock).returns(decision)

                    // when
                    let actual = sut.featureFlagDetail(featureKey: 42)

                    // then
                    expect(actual).to(beIdenticalTo(decision))
                    expect(userManager.hackleUserMock.firstInvokation().arguments.0).to(beIdenticalTo(userManager.currentUser))
                }

                it("when core throws then return off decision") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.hackleUserMock).returns(hackleUser)

                    every(core.featureFlagMock).willThrow(HackleError.error("fail"))

                    // when
                    let actual = sut.featureFlagDetail(featureKey: 42)

                    // then
                    expect(actual.isOn) == false
                    expect(actual.reason) == DecisionReason.EXCEPTION
                    expect(userManager.hackleUserMock.firstInvokation().arguments.0).to(beIdenticalTo(userManager.currentUser))
                }
            }
        }

        describe("track") {
            it("eventKey") {
                // given
                let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                every(userManager.hackleUserMock).returns(hackleUser)

                // when
                sut.track(eventKey: "42")

                // then
                let (event, user, _) = core.trackMock.firstInvokation().arguments
                expect(event.key) == "42"
                expect(user).to(beIdenticalTo(hackleUser))
            }

            it("event") {
                // given
                let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                every(userManager.hackleUserMock).returns(hackleUser)
                let event = Event.builder("42").build()

                // when
                sut.track(event: event)

                // then
                let (e, user, _) = core.trackMock.firstInvokation().arguments
                expect(e).to(beIdenticalTo(event))
                expect(user).to(beIdenticalTo(hackleUser))
            }
        }

        describe("remoteConfig") {
            it("return DefaultRemoteConfig") {
                let actual = sut.remoteConfig()
                expect(actual).to(beAnInstanceOf(DefaultRemoteConfig.self))
            }
        }

        it("initialize") {
            var count = 0
            sut.initialize(user: nil) {
                count += 1
            }
            expect(count) == 0

            expect(count).toEventually(equal(1), timeout: .seconds(10))

            expect(userManager.initializeMock.firstInvokation().arguments).to(beNil())
            expect(platformManager.device.properties.count) == 13
        }

        it("initialize — sync 완료 후에 flush가 실행된다") {
            var order: [String] = []
            every(synchronizer.syncMock).answers { _ in
                Thread.sleep(forTimeInterval: 0.1)
                order.append("sync")
            }
            notificationManager.onFlush = {
                order.append("flush")
            }

            waitUntil(timeout: .seconds(10)) { done in
                sut.initialize(user: nil) {
                    done()
                }
            }

            expect(order) == ["sync", "flush"]
        }

        it("create") {
            let config = HackleConfig.builder()
                .sdkUrl(URL(string: "http://localhost")!)
                .eventUrl(URL(string: "http://localhost")!)
                .monitoringUrl(URL(string: "http://localhost")!)
                .build()
            let app = HackleApp.create(sdkKey: "sdk_key", config: config)
            expect(app.deviceId) == UserDefaults.standard.string(forKey: "hackle_device_id")
        }

        describe("updateMarketingSubscriptionStatus") {
            it("set push subscribed") {
                sut.updatePushSubscriptions(
                    operations: HackleSubscriptionOperations
                        .builder()
                        .marketing(.unsubscribed)
                        .information(.subscribed)
                        .custom("chat", status: .unknown)
                        .build()
                )

                verify(exactly: 1) {
                    core.trackMock
                }
                verify(exactly: 1) {
                    eventProcessor.flushMock
                }
                expect(core.trackMock.firstInvokation().arguments.0.key) == "$push_subscriptions"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["$marketing"] as? String) == "UNSUBSCRIBED"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["$information"] as? String) == "SUBSCRIBED"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["chat"] as? String) == "UNKNOWN"
            }

            it("set sms subscribed") {
                sut.updateSmsSubscriptions(
                    operations: HackleSubscriptionOperations
                        .builder()
                        .marketing(.unsubscribed)
                        .information(.subscribed)
                        .custom("chat", status: .unknown)
                        .build()
                )
                verify(exactly: 1) {
                    core.trackMock
                }
                verify(exactly: 1) {
                    eventProcessor.flushMock
                }
                expect(core.trackMock.firstInvokation().arguments.0.key) == "$sms_subscriptions"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["$marketing"] as? String) == "UNSUBSCRIBED"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["$information"] as? String) == "SUBSCRIBED"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["chat"] as? String) == "UNKNOWN"
            }

            it("set kakaotalk subscribed") {
                sut.updateKakaoSubscriptions(
                    operations: HackleSubscriptionOperations
                        .builder()
                        .marketing(.unsubscribed)
                        .information(.subscribed)
                        .custom("chat", status: .unknown)
                        .build()
                )
                verify(exactly: 1) {
                    core.trackMock
                }
                verify(exactly: 1) {
                    eventProcessor.flushMock
                }
                expect(core.trackMock.firstInvokation().arguments.0.key) == "$kakao_subscriptions"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["$marketing"] as? String) == "UNSUBSCRIBED"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["$information"] as? String) == "SUBSCRIBED"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["chat"] as? String) == "UNKNOWN"
            }
        }

        describe("setCurrentScreen") {
            it("set") {
                let screen = Screen.builder(name: "currentScreen", className: "currentClass").build()
                sut.setCurrentScreen(screen: screen)
                verify(exactly: 1) {
                    screenManager.setCurrentScreenMock
                }
                expect(screenManager.currentScreen) == screen
            }
        }

        describe("fetch") {
            it("fetch - 스로틀(reject) 시에도 completion이 호출된다") {
                let rejectingBuilt = makeHackleApp(
                    core: core,
                    coreQueue: eventQueue,
                    synchronizer: synchronizer,
                    userManager: userManager,
                    workspaceManager: workspaceManager,
                    sessionManager: sessionManager,
                    screenManager: screenManager,
                    eventProcessor: eventProcessor,
                    pushTokenRegistry: pushTokenRegistry,
                    notificationManager: notificationManager,
                    platformManager: platformManager,
                    userExplorer: userExplorer,
                    inAppMessageUI: inAppMessageUI,
                    throttler: RejectingThrottler()
                )
                let rejectingSut = rejectingBuilt.sut

                waitUntil { done in
                    rejectingSut.fetch {
                        done()
                    }
                }
            }
        }
    }
}

private class RejectingThrottler: Throttler {
    func execute(accept: @escaping () -> (), reject: @escaping () -> ()) {
        reject()
    }
}
