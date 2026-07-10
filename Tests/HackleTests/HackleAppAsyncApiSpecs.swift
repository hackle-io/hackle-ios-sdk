import Foundation
import Nimble
import Quick
@testable import Hackle

class HackleAppAsyncApiSpecs: AsyncSpec {
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
                eventQueue: eventQueue,
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

        it("setUser async — 반환 시 유저 갱신과 sync가 모두 완료된다") {
            let user = User.builder().id("async-user").build()
            await awaitCompletion {
                await sut.setUser(user: user)
                expect(userManager.currentUser.id) == "async-user"
                // mutator가 sync 책임을 흡수 — setUserMock 호출 완료가 곧 update+sync 완료를 의미한다
                verify(exactly: 1) {
                    userManager.setUserMock
                }
            }
        }

        it("updateUserProperties async — non-suspending으로 완료된다") {
            await awaitCompletion {
                await sut.updateUserProperties(operations: PropertyOperations.builder().set("k", "v").build())
                verify(exactly: 1) {
                    userManager.updatePropertiesMock
                }
            }
        }

        it("fetch async — sync 완료 후 반환된다") {
            await awaitCompletion {
                await sut.fetch()
                verify(exactly: 1) {
                    synchronizer.syncMock
                }
            }
        }
    }
}
