import Foundation
@testable import Hackle

/// 모든 HackleApp SUT 배선이 공유하는 inAppMessage UI 체인.
func makeInAppMessageUI(core: HackleCore) -> HackleInAppMessageUI {
    let inAppMessageActionHandlerFactory = DefaultInAppMessageActionHandlerFactory(handlers: [])
    let inAppMessageViewEventActorFactory = DefaultInAppMessageViewEventActorFactory(actors: [
        InAppMessageViewImpressionEventActor(),
        InAppMessageViewActionEventActor(actionHandlerFactory: inAppMessageActionHandlerFactory),
        InAppMessageViewCloseEventActor()
    ])
    let inAppMessageViewEventActionHandler = InAppMessageViewEventActionHandler(
        actorFactory: inAppMessageViewEventActorFactory
    )
    let inAppMessageEventTracker = DefaultInAppMessageEventTracker(core: core)
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
    return HackleInAppMessageUI(
        clock: SystemClock.shared,
        eventProcessor: inAppMessageViewEventProcessor,
        htmlContentResolverFactory: MockInAppMessageHtmlContentResolverFactory()
    )
}

/// DefaultHackleAppCore + HackleApp 배선. 각 테스트는 자신이 참조할 mock을 주입한다.
func makeHackleApp(
    core: HackleCore,
    evaluationMode: EvaluationMode = .local,
    coreQueue: DispatchQueue,
    synchronizer: Synchronizer,
    userManager: UserManager,
    workspaceManager: WorkspaceConfigManager,
    sessionManager: SessionManager,
    screenManager: ScreenManager,
    eventProcessor: UserEventProcessor,
    pushTokenRegistry: PushTokenRegistry,
    notificationManager: NotificationManager,
    platformManager: PlatformManager,
    userExplorer: HackleUserExplorer,
    inAppMessageUI: HackleInAppMessageUI,
    throttler: Throttler
) -> (core: DefaultHackleAppCore, sut: HackleApp) {
    let applicationInstallStateManager = ApplicationInstallStateManager(
        platformManager: platformManager,
        applicationInstallDeterminer: ApplicationInstallDeterminer(),
        clock: SystemClock.shared
    )
    let hackleAppCore = DefaultHackleAppCore(
        core: core,
        evaluationMode: evaluationMode,
        coreQueue: coreQueue,
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
    let sut = HackleApp(
        hackleAppCore: hackleAppCore,
        sdk: Sdk.of(sdkKey: "abcd1234", config: HackleConfig.DEFAULT),
        config: HackleConfig.builder().mode(.native).build(),
        hackleInvocator: DefaultHackleInvocator(
            processor: DefaultInvocationProcessor(
                handlerFactory: DefaultInvocationHandlerFactory(core: hackleAppCore)
            )
        )
    )
    return (hackleAppCore, sut)
}
