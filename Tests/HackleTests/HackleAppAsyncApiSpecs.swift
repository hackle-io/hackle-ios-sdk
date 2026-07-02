import Foundation
import Nimble
import Quick
@testable import Hackle

class HackleAppAsyncApiSpecs: QuickSpec {
    override class func spec() {
        var core: MockHackleCore!
        var eventQueue: DispatchQueue!
        var synchronizer: MockSynchronizer!
        var platformManager: PlatformManager!
        var userManager: MockUserManager!
        var workspaceManager: WorkspaceManager!
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
            workspaceManager = WorkspaceManager(
                httpWorkspaceFetcher: MockHttpWorkspaceFetcher(returns: []),
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
                abTestOverrideStorage: HackleUserManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                featureFlagOverrideStorage: HackleUserManualOverrideStorage(keyValueRepository: MemoryKeyValueRepository()),
                devToolsAPI: MockDevToolsAPI()
            )
            let urlHandler = ApplicationUrlHandler()
            let inAppMessageActionHandlerFactory = DefaultInAppMessageActionHandlerFactory(handlers: [])
            let inAppMessageViewEventActorFactory = DefaultInAppMessageViewEventActorFactory(actors: [
                InAppMessageViewImpressionEventActor(),
                InAppMessageViewActionEventActor(actionHandlerFactory: inAppMessageActionHandlerFactory),
                InAppMessageViewCloseEventActor()
            ])
            let inAppMessageViewEventActionHandler = InAppMessageViewEventActionHandler(
                actorFactory: inAppMessageViewEventActorFactory
            )
            let inAppMessageEventTracker = DefaultInAppMessageEventTracker(
                core: core
            )
            let inAppMessageViewEventTrackHandler = InAppMessageViewEventTrackHandler(
                tracker: inAppMessageEventTracker
            )
            let inAppMessageViewEventHandlerFactory = DefaultInAppMessageViewEventHandlerFactory(handlers: [
                inAppMessageViewEventActionHandler,
                inAppMessageViewEventTrackHandler
            ])
            let inAppMessageViewEventProcessor = DefaultInAppMessageViewEventProcessor(
                handlerFactory: inAppMessageViewEventHandlerFactory
            )
            inAppMessageUI = HackleInAppMessageUI(
                clock: SystemClock.shared,
                eventProcessor: inAppMessageViewEventProcessor,
                htmlContentResolverFactory: MockInAppMessageHtmlContentResolverFactory()
            )

            let applicationInstallDeterminer = ApplicationInstallDeterminer()
            let applicationInstallStateManager = ApplicationInstallStateManager(
                platformManager: platformManager,
                applicationInstallDeterminer: applicationInstallDeterminer,
                clock: SystemClock.shared
            )

            let throttler = DefaultThrottler(limiter: ScopingThrottleLimiter(interval: 10, limit: 1, clock: SystemClock.shared))

            let hackleAppCore = DefaultHackleAppCore(
                core: core,
                eventQueue: eventQueue,
                synchronizer: synchronizer,
                applicationLifecycleObserver: ApplicationLifecycleObserver.shared,
                viewLifecycleObserver: ViewLifecycleObserver.shared,
                userManager: userManager,
                workspaceManager: workspaceManager,
                sessionManager: sessionManager,
                screenManager: screenManager,
                eventProcessor: eventProcessor,
                pushTokenRegistry: pushTokenRegistry,
                notificationManager: notificationManager,
                fetchThrottler: throttler,
                platformManager: platformManager,
                inAppMessageUI: inAppMessageUI,
                applicationInstallStateManager: applicationInstallStateManager,
                userExplorer: userExplorer,
                optOutManager: OptOutManager(configOptOutTracking: false)
            )
            sut = HackleApp(
                hackleAppCore: hackleAppCore,
                sdk: Sdk.of(sdkKey: "abcd1234", config: HackleConfig.DEFAULT),
                config: HackleConfig.builder().mode(.native).build(),
                hackleInvocator: DefaultHackleInvocator(processor: DefaultInvocationProcessor(handlerFactory: DefaultInvocationHandlerFactory(core: hackleAppCore)))
            )
        }

        it("setUser async — 반환 시 유저 갱신과 sync가 모두 완료된다") {
            let user = User.builder().id("async-user").build()
            waitUntil { done in
                Task {
                    await sut.setUser(user: user)
                    expect(userManager.currentUser.id) == "async-user"
                    verify(exactly: 1) {
                        userManager.syncIfNeededMock
                    }
                    done()
                }
            }
        }

        it("updateUserProperties async — non-suspending으로 완료된다") {
            waitUntil { done in
                Task {
                    await sut.updateUserProperties(operations: PropertyOperations.builder().set("k", "v").build())
                    done()
                }
            }
        }

        it("fetch async — sync 완료 후 반환된다") {
            waitUntil { done in
                Task {
                    await sut.fetch()
                    done()
                }
            }
        }
    }
}
