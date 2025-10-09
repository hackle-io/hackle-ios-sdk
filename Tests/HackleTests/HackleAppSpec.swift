import Foundation
import Nimble
import Quick
@testable import Hackle

class HackleAppSpecs: QuickSpec {
    override func spec() {
        var core: MockHackleCore!
        var eventQueue: DispatchQueue!
        var synchronizer: MockSynchronizer!
        var userManager: MockUserManager!
        var workspaceManager: WorkspaceManager!
        var notificationManager: MockNotificationManager!
        var sessionManager: MockSessionManager!
        var screenManager: MockScreeManager!
        var eventProcessor: MockUserEventProcessor!
        var pushTokenRegistry = DefaultPushTokenRegistry()
        var device: Device!
        var userExplorer: HackleUserExplorer!
        var inAppMessageUI: HackleInAppMessageUI!

        var sut: HackleApp!

        beforeEach {
            Metrics.clear()
            core = MockHackleCore()
            eventQueue = DispatchQueue(label: "io.hackle.EventQueue", qos: .utility)
            synchronizer = MockSynchronizer()
            userManager = MockUserManager()
            workspaceManager = WorkspaceManager(
                httpWorkspaceFetcher: MockHttpWorkspaceFetcher(returns: []),
                repository: MockWorkspaceConfigRepository()
            )
            notificationManager = MockNotificationManager()
            sessionManager = MockSessionManager()
            screenManager = MockScreeManager()
            eventProcessor = MockUserEventProcessor()
            pushTokenRegistry = DefaultPushTokenRegistry()
            device = MockDevice(id: "hackle_device_id", isIdCreated: true, properties: [:])
            userExplorer = DefaultHackleUserExplorer(
                core: core,
                userManager: userManager,
                pushTokenManager: MockPushTokenManager(),
                abTestOverrideStorage: HackleUserManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                featureFlagOverrideStorage: HackleUserManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                devToolsAPI: MockDevToolsAPI()
            )
            
            let inAppMessageEventProcessorFactory = InAppMessageEventProcessorFactory(processors: [])
            let inAppMessageEventHandler = DefaultInAppMessageEventHandler(
                clock: SystemClock.shared,
                eventTracker: DefaultInAppMessageEventTracker(core: core),
                processorFactory: inAppMessageEventProcessorFactory
            )
            inAppMessageUI = HackleInAppMessageUI(eventHandler: inAppMessageEventHandler)
            
            let applicationInstallDeterminer = ApplicationInstallDeterminer(keyValueRepository: MemoryKeyValueRepository(), device: device, bundleInfo: BundleInfoImpl(previousVersion: nil, previousBuild: nil))
            let applicationInstallStateManager = ApplicationInstallStateManager(clock: SystemClock.shared, queue: eventQueue, applicationInstallDeterminer: applicationInstallDeterminer)
            
            let throttler = DefaultThrottler(limiter: ScopingThrottleLimiter(interval: 10, limit: 1, clock: SystemClock.shared))
            
            let hackleAppCore = DefaultHackleAppCore(
                core: core,
                eventQueue: eventQueue,
                synchronizer: synchronizer,
                userManager: userManager,
                workspaceManager: workspaceManager,
                sessionManager: sessionManager,
                screenManager: screenManager,
                eventProcessor: eventProcessor,
                pushTokenRegistry: pushTokenRegistry,
                notificationManager: notificationManager,
                fetchThrottler: throttler,
                device: device,
                inAppMessageUI: inAppMessageUI,
                applicationInstallStateManager: applicationInstallStateManager,
                userExplorer: userExplorer
            )
            sut = HackleApp(
                hackleAppCore: hackleAppCore,
                mode: .native,
                sdk: Sdk.of(sdkKey: "abcd1234", config: HackleConfig.DEFAULT),
                hackleInvocator: DefaultHackleInvocator(hackleAppCore: hackleAppCore)
            )
        }

        it("deviceId") {
            expect(sut.deviceId) == "hackle_device_id"
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

        it("hideUserExplorer") {
            sut.hideUserExplorer()
        }

        describe("setUser") {
            it("set and sync") {
                let user = User.builder().id("42").build()
                sut.setUser(user: user)
                verify(exactly: 1) {
                    userManager.setUserMock
                }
                verify(exactly: 1) {
                    userManager.syncIfNeededMock
                }
                expect(userManager.setUserMock.firstInvokation().arguments).to(beIdenticalTo(user))
            }

            it("completion") {
                var count = 0
                let user = User.builder().id("42").build()
                sut.setUser(user: user) {
                    count += 1
                }
                expect(count) == 1
            }
        }

        describe("setUserId") {
            it("set and sync") {
                sut.setUserId(userId: "user_id")
                verify(exactly: 1) {
                    userManager.setUserIdMock
                }
                verify(exactly: 1) {
                    userManager.syncIfNeededMock
                }
                expect(userManager.setUserIdMock.firstInvokation().arguments) == "user_id"
            }

            it("completion") {
                var count = 0
                sut.setUserId(userId: "user_id") {
                    count += 1
                }
                expect(count) == 1
            }
        }

        describe("setDeviceId") {
            it("set and sync") {
                sut.setDeviceId(deviceId: "device_id")
                verify(exactly: 1) {
                    userManager.setDeviceIdMock
                }
                verify(exactly: 1) {
                    userManager.syncIfNeededMock
                }
                expect(userManager.setDeviceIdMock.firstInvokation().arguments) == "device_id"
            }

            it("completion") {
                var count = 0
                sut.setDeviceId(deviceId: "device_id") {
                    count += 1
                }
                expect(count) == 1
            }
        }

        describe("resetUser") {
            it("reset") {
                sut.resetUser()
                verify(exactly: 1) {
                    userManager.resetUserMock
                }
                verify(exactly: 1) {
                    core.trackMock
                }
                verify(exactly: 1) {
                    userManager.syncIfNeededMock
                }
                expect(core.trackMock.firstInvokation().arguments.0.key) == "$properties"
            }
            it("completion") {
                var count = 0
                sut.resetUser {
                    count += 1
                }
                expect(count) == 1
            }
        }

        describe("setUserProperty") {
            it("update properties") {
                sut.setUserProperty(key: "age", value: 42)
                verify(exactly: 1) {
                    userManager.updatePropertiesMock
                }
                verify(exactly: 1) {
                    core.trackMock
                }
                verify(exactly: 1) {
                    eventProcessor.flushMock
                }
                verify(exactly: 0) {
                    userManager.syncIfNeededMock
                }
                expect(userManager.updatePropertiesMock.firstInvokation().arguments.asDictionary()[.set] as? [String: Int]) == ["age": 42]
                expect(core.trackMock.firstInvokation().arguments.0.key) == "$properties"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["$set"] as? [String: Int]) == ["age": 42]
            }

            it("completion") {
                var count = 0
                sut.setUserProperty(key: "age", value: 42) {
                    count += 1
                }
                expect(count) == 1
            }
        }

        describe("updateUserProperties") {
            it("update properties") {
                sut.updateUserProperties(operations: PropertyOperations.builder().set("age", 42).build())
                verify(exactly: 1) {
                    userManager.updatePropertiesMock
                }
                verify(exactly: 1) {
                    core.trackMock
                }
                verify(exactly: 1) {
                    eventProcessor.flushMock
                }
                verify(exactly: 0) {
                    userManager.syncIfNeededMock
                }
                expect(core.trackMock.firstInvokation().arguments.0.key) == "$properties"
                expect(core.trackMock.firstInvokation().arguments.0.properties?["$set"] as? [String: Int]) == ["age": 42]
            }

            it("completion") {
                var count = 0
                sut.updateUserProperties(operations: PropertyOperations.builder().set("age", 42).build()) {
                    count += 1
                }
                expect(count) == 1
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
                sut.setPhoneNumber(phoneNumber: "+821012345678") {
                    count += 1
                }
                expect(count) == 1
            }
            
            it("unsetPhoneNumber") {
                var count = 0
                sut.unsetPhoneNumber() {
                    count += 1
                }
                expect(count) == 1
            }
        }

        describe("experiment") {

            it("variation") {
                // given
                let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                every(userManager.resolveMock).returns(hackleUser)

                let decision = Decision.of(experiment: nil, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                every(core.experimentMock).returns(decision)

                // when
                let actual = sut.variation(experimentKey: 42)

                // then
                expect(actual) == "B"
                expect(userManager.resolveMock.firstInvokation().arguments.0).to(beNil())
            }

            describe("variationDetail") {
                it("success") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.resolveMock).returns(hackleUser)

                    let decision = Decision.of(experiment: nil, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                    every(core.experimentMock).returns(decision)

                    // when
                    let actual = sut.variationDetail(experimentKey: 42)

                    // then
                    expect(actual).to(beIdenticalTo(decision))
                    expect(userManager.resolveMock.firstInvokation().arguments.0).to(beNil())
                }

                it("error") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.resolveMock).returns(hackleUser)

                    every(core.experimentMock).willThrow(HackleError.error("fail"))

                    // when
                    let actual = sut.variationDetail(experimentKey: 42)

                    // then
                    expect(actual.variation) == "A"
                    expect(actual.reason) == DecisionReason.EXCEPTION
                    expect(userManager.resolveMock.firstInvokation().arguments.0).to(beNil())
                }
            }

            describe("allVariationDetailsInternal") {
                it("success") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.resolveMock).returns(hackleUser)

                    let experiment = MockExperiment(id: 1, key: 42)
                    let decision = Decision.of(experiment: experiment, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED)
                    let decisions = [(experiment, decision)]
                    every(core.experimentsMock).returns(decisions)

                    // when
                    let actual = sut.allVariationDetails()

                    // then
                    expect(actual[42]).to(beIdenticalTo(decision))
                    expect(userManager.resolveMock.firstInvokation().arguments.0).to(beNil())
                }

                it("error") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.resolveMock).returns(hackleUser)

                    every(core.experimentsMock).willThrow(HackleError.error("fail"))

                    // when
                    let actual = sut.allVariationDetails()

                    // then
                    expect(actual.count) == 0
                    expect(userManager.resolveMock.firstInvokation().arguments.0).to(beNil())
                }
            }
        }

        describe("feature flag") {
            it("isFeatureOn") {
                // given
                let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                every(userManager.resolveMock).returns(hackleUser)


                let decision = FeatureFlagDecision.on(featureFlag: nil, reason: DecisionReason.DEFAULT_RULE)
                every(core.featureFlagMock).returns(decision)

                // when
                let actual = sut.isFeatureOn(featureKey: 42)

                // then
                expect(actual) == true
                expect(userManager.resolveMock.firstInvokation().arguments.0).to(beNil())
            }

            describe("featureFlagDetail") {
                it("success") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.resolveMock).returns(hackleUser)

                    let decision = FeatureFlagDecision.on(featureFlag: nil, reason: DecisionReason.DEFAULT_RULE)
                    every(core.featureFlagMock).returns(decision)

                    // when
                    let actual = sut.featureFlagDetail(featureKey: 42)

                    // then
                    expect(actual).to(beIdenticalTo(decision))
                    expect(userManager.resolveMock.firstInvokation().arguments.0).to(beNil())
                }

                it("error") {
                    // given
                    let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                    every(userManager.resolveMock).returns(hackleUser)

                    every(core.featureFlagMock).willThrow(HackleError.error("fail"))

                    // when
                    let actual = sut.featureFlagDetail(featureKey: 42)

                    // then
                    expect(actual.isOn) == false
                    expect(actual.reason) == DecisionReason.EXCEPTION
                    expect(userManager.resolveMock.firstInvokation().arguments.0).to(beNil())
                }
            }

        }

        describe("track") {

            it("eventKey") {
                // given
                let hackleUser = HackleUser.builder().identifier("$id", "42").build()
                every(userManager.resolveMock).returns(hackleUser)

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
                every(userManager.resolveMock).returns(hackleUser)
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

            every(sessionManager.initializeMock).answers {
                Thread.sleep(forTimeInterval: 0.1)
            }

            every(eventProcessor.initializeMock).answers {
                Thread.sleep(forTimeInterval: 0.1)
            }

            var count = 0
            sut.initialize(user: nil) {
                count += 1
            }
            expect(count) == 0

            Thread.sleep(forTimeInterval: 0.1)
            expect(count) == 0

            Thread.sleep(forTimeInterval: 0.05)
            expect(count) == 0

            eventQueue.sync {
            }
            expect(count) == 1

            expect(userManager.initializeMock.firstInvokation().arguments).to(beNil())
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
                let screen = Screen(name: "currentScreen", className: "currentClass")
                sut.setCurrentScreen(screen: screen)
                verify(exactly: 1) {
                    screenManager.setCurrentScreenMock
                }
                expect(screenManager.currentScreen) == screen
            }
        }

        describe("DEPRECATED") {

            describe("experiment") {
                beforeEach {
                    every(core.experimentMock).returns(Decision.of(experiment: nil, variation: "B", reason: DecisionReason.TRAFFIC_ALLOCATED))
                    every(core.experimentsMock).returns([])
                }

                it("variation - userId") {
                    expect(sut.variation(experimentKey: 42, userId: "user_id")) == "B"
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }

                it("variation - user") {
                    let user = User.builder().id("user_id").build()
                    expect(sut.variation(experimentKey: 42, user: user)) == "B"
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }

                it("variationDetail - userId") {
                    expect(sut.variationDetail(experimentKey: 42, userId: "user_id").variation) == "B"
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }

                it("variationDetail - user") {
                    let user = User.builder().id("user_id").build()
                    expect(sut.variationDetail(experimentKey: 42, user: user).variation) == "B"
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }

                it("allVariationDetails") {
                    let user = User.builder().id("user_id").build()
                    expect(sut.allVariationDetails(user: user).count) == 0
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }
            }
            describe("feature flag") {
                beforeEach {
                    every(core.featureFlagMock).returns(FeatureFlagDecision.on(featureFlag: nil, reason: DecisionReason.DEFAULT_RULE))
                }

                it("isFeatureOn - userId") {
                    expect(sut.isFeatureOn(featureKey: 42, userId: "user_id")) == true
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }

                it("isFeatureOn - user") {
                    let user = User.builder().id("user_id").build()
                    expect(sut.isFeatureOn(featureKey: 42, user: user)) == true
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }

                it("featureFlagDetail - userId") {
                    expect(sut.featureFlagDetail(featureKey: 42, userId: "user_id").isOn) == true
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }

                it("featureFlagDetail - user") {
                    let user = User.builder().id("user_id").build()
                    expect(sut.featureFlagDetail(featureKey: 42, user: user).isOn) == true
                    expect(userManager.resolveMock.firstInvokation().arguments.0?.id) == "user_id"
                }
            }

            it("track") {
                sut.track(eventKey: "test", userId: "user_id")
                sut.track(eventKey: "test", user: User.builder().id("user_id").build())
                sut.track(event: Event.builder("test").build(), userId: "user_id")
                sut.track(event: Event.builder("test").build(), user: User.builder().id("user_id").build())

                verify(exactly: 4) {
                    userManager.resolveMock
                }

                for invokation in userManager.resolveMock.invokations() {
                    expect(invokation.arguments.0?.id) == "user_id"
                }
            }

            it("remoteConfig") {
                let user = User.builder().id("user_id").build()
                let actual = sut.remoteConfig(user: user)
                expect(actual).to(beAnInstanceOf(DefaultRemoteConfig.self))
            }
        }
    }
}
