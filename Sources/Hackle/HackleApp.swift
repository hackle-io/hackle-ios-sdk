//
// Created by yong on 2020/12/11.
//

import Foundation
import WebKit

/// Entry point of Hackle Sdk.
@objc public final class HackleApp: NSObject {
    private let hackleAppCore: HackleAppCore
    private let sdk: Sdk
    private let mode: HackleAppMode
    private let hackleInvocator: HackleInvocator

    init(
        hackleAppCore: HackleAppCore,
        mode: HackleAppMode,
        sdk: Sdk,
        hackleInvocator: HackleInvocator
    ) {
        self.hackleAppCore = hackleAppCore
        self.mode = mode
        self.sdk = sdk
        self.hackleInvocator = hackleInvocator
        super.init()
    }

    @objc public var inAppMessageDelegate: HackleInAppMessageDelegate? {
        didSet {
            hackleAppCore.setInAppMessageDelegate(inAppMessageDelegate)
        }
    }

    @objc public var deviceId: String {
        get {
            hackleAppCore.deviceId
        }
    }

    @objc public var sessionId: String {
        get {
            hackleAppCore.sessionId
        }
    }

    @objc public var user: User {
        get {
            hackleAppCore.user
        }
    }

    @objc public func showUserExplorer() {
        hackleAppCore.showUserExplorer()
    }

    @objc public func hideUserExplorer() {
        hackleAppCore.hideUserExplorer()
        hackleAppCore.hideUserExplorer()
    }

    @objc public func setUser(user: User) {
        setUser(user: user, completion: {})
    }

    @objc public func setUser(user: User, completion: @escaping () -> ()) {
        hackleAppCore.setUser(user: user, hackleAppContext: .default, completion: completion)
    }

    @objc public func setUserId(userId: String?) {
        setUserId(userId: userId, completion: {})
    }

    @objc public func setUserId(userId: String?, completion: @escaping () -> ()) {
        hackleAppCore.setUserId(userId: userId, hackleAppContext: .default, completion: completion)
    }

    @objc public func setDeviceId(deviceId: String) {
        setDeviceId(deviceId: deviceId, completion: {})
    }

    @objc public func setDeviceId(deviceId: String, completion: @escaping () -> ()) {
        hackleAppCore.setDeviceId(deviceId: deviceId, hackleAppContext: .default, completion: completion)
    }

    @objc public func setUserProperty(key: String, value: Any?) {
        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()
        updateUserProperties(operations: operations)
    }

    @objc public func setUserProperty(key: String, value: Any?, completion: @escaping () -> ()) {
        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()
        updateUserProperties(operations: operations, completion: completion)
    }

    @objc public func updateUserProperties(operations: PropertyOperations) {
        updateUserProperties(operations: operations, completion: {})
    }

    @objc public func updateUserProperties(operations: PropertyOperations, completion: @escaping () -> ()) {
        hackleAppCore.updateUserProperties(operations: operations, hackleAppContext: .default, completion: completion)
    }

    @objc public func updatePushSubscriptions(operations: HackleSubscriptionOperations) {
        hackleAppCore.updatePushSubscriptions(operations: operations, hackleAppContext: .default)
    }

    @objc public func updateSmsSubscriptions(operations: HackleSubscriptionOperations) {
        hackleAppCore.updateSmsSubscriptions(operations: operations, hackleAppContext: .default)
    }


    @objc public func updateKakaoSubscriptions(operations: HackleSubscriptionOperations) {
        hackleAppCore.updateKakaoSubscriptions(operations: operations, hackleAppContext: .default)
    }

    @objc public func resetUser() {
        resetUser(completion: {})
    }

    @objc public func resetUser(completion: @escaping () -> ()) {
        hackleAppCore.resetUser(hackleAppContext: .default, completion: completion)
    }

    @objc public func setPhoneNumber(phoneNumber: String) {
        setPhoneNumber(phoneNumber: phoneNumber, completion: {})
    }

    @objc public func setPhoneNumber(phoneNumber: String, completion: @escaping () -> ()) {
        hackleAppCore.setPhoneNumber(phoneNumber: phoneNumber, hackleAppContext: .default, completion: completion)
    }

    @objc public func unsetPhoneNumber() {
        unsetPhoneNumber(completion: {})
    }

    @objc public func unsetPhoneNumber(completion: @escaping () -> ()) {
        hackleAppCore.unsetPhoneNumber(hackleAppContext: .default, completion: completion)
    }

    @objc public func variation(experimentKey: Int, defaultVariation: String = "A") -> String {
        variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation).variation
    }

    @objc public func variationDetail(experimentKey: Int, defaultVariation: String = "A") -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: nil, defaultVariation: defaultVariation, hackleAppContext: .default)
    }

    @objc public func allVariationDetails() -> [Int: Decision] {
        hackleAppCore.allVariationDetails(user: nil, hackleAppContext: .default)
    }

    @objc public func isFeatureOn(featureKey: Int) -> Bool {
        featureFlagDetail(featureKey: featureKey).isOn
    }

    @objc public func featureFlagDetail(featureKey: Int) -> FeatureFlagDecision {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: nil, hackleAppContext: .default)
    }

    @objc public func track(eventKey: String) {
        track(event: Hackle.event(key: eventKey))
    }

    @objc public func track(event: Event) {
        hackleAppCore.track(event: event, user: nil, hackleAppContext: .default)
    }

    @objc public func remoteConfig() -> HackleRemoteConfig {
        DefaultRemoteConfig(hackleAppCore: hackleAppCore, user: nil)
    }

    @objc public func setWebViewBridge(_ webView: WKWebView, _ uiDelegate: WKUIDelegate? = nil) {
        webView.prepareForHackleWebBridge(invocator: invocator(), sdkKey: sdk.key, mode: mode, uiDelegate: uiDelegate)
    }

    @objc public func invocator() -> HackleInvocator {
        return hackleInvocator
    }

    @objc public func setPushToken(_ deviceToken: Data) {
        hackleAppCore.setPushToken(deviceToken: deviceToken)
    }

    @objc public func fetch(_ completion: @escaping () -> ()) {
        hackleAppCore.fetch(completion: completion)
    }

    @objc public func setCurrentScreen(screen: Screen) {
        hackleAppCore.setCurrentScreen(screen: screen, hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    @objc public func variation(experimentKey: Int, userId: String, defaultVariation: String = "A") -> String {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: Hackle.user(id: userId), defaultVariation: defaultVariation, hackleAppContext: .default).variation
    }

    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    @objc public func variation(experimentKey: Int, user: User, defaultVariation: String = "A") -> String {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: user, defaultVariation: defaultVariation, hackleAppContext: .default).variation
    }

    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    @objc public func variationDetail(experimentKey: Int, userId: String, defaultVariation: String = "A") -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: Hackle.user(id: userId), defaultVariation: defaultVariation, hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    @objc public func variationDetail(experimentKey: Int, user: User, defaultVariation: String = "A") -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: user, defaultVariation: defaultVariation, hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use allVariationDetails() with setUser(user) instead.")
    @objc public func allVariationDetails(user: User) -> [Int: Decision] {
        hackleAppCore.allVariationDetails(user: user, hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    @objc public func isFeatureOn(featureKey: Int, userId: String) -> Bool {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: Hackle.user(id: userId), hackleAppContext: .default).isOn
    }

    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    @objc public func isFeatureOn(featureKey: Int, user: User) -> Bool {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: user, hackleAppContext: .default).isOn
    }

    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    @objc public func featureFlagDetail(featureKey: Int, userId: String) -> FeatureFlagDecision {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: Hackle.user(id: userId), hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    @objc public func featureFlagDetail(featureKey: Int, user: User) -> FeatureFlagDecision {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: user, hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    @objc public func track(eventKey: String, userId: String) {
        hackleAppCore.track(event: Hackle.event(key: eventKey), user: Hackle.user(id: userId), hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    @objc public func track(eventKey: String, user: User) {
        hackleAppCore.track(event: Hackle.event(key: eventKey), user: user, hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    @objc public func track(event: Event, userId: String) {
        hackleAppCore.track(event: event, user: Hackle.user(id: userId), hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    @objc public func track(event: Event, user: User) {
        hackleAppCore.track(event: event, user: user, hackleAppContext: .default)
    }

    @available(*, deprecated, message: "Use remoteConfig() with setUser(user) instead.")
    @objc public func remoteConfig(user: User) -> HackleRemoteConfig {
        DefaultRemoteConfig(hackleAppCore: hackleAppCore, user: user)
    }

    @available(*, deprecated, message: "Do not use this method because it does nothing. Use `updatePushSubscriptions(operations)` instead.")
    @objc public func updatePushSubscriptionStatus(status: HacklePushSubscriptionStatus) {
        Log.error("updatePushSubscriptionStatus does nothing. Use updatePushSubscriptions(operations) instead.")
    }
}

extension HackleApp {
    func initialize(user: User? = nil, completion: @escaping () -> ()) {
        hackleAppCore.initialize(user: user, completion: completion)
    }

    static func create(sdkKey: String, config: HackleConfig) -> HackleApp {
        let sdk = Sdk.of(sdkKey: sdkKey, config: config)

        let scheduler = Schedulers.dispatch()
        let globalKeyValueRepository = UserDefaultsKeyValueRepository(userDefaults: UserDefaults.standard, suiteName: nil)
        let keyValueRepositoryBySdkKey = UserDefaultsKeyValueRepository.of(suiteName: String(format: storageSuiteNameDefault, sdkKey))
        let device = DeviceImpl.create(keyValueRepository: globalKeyValueRepository)

        let httpClient = DefaultHttpClient(sdk: sdk)

        // - Synchronizer

        let compositeSynchronizer = CompositeSynchronizer(
            dispatchQueue: DispatchQueue(label: "io.hackle.DelegatingSynchronizer", attributes: .concurrent)
        )
        let pollingSynchronizer = PollingSynchronizer(
            delegate: compositeSynchronizer,
            scheduler: scheduler,
            interval: config.pollingInterval
        )

        // - WorkspaceFetcher

        let httpWorkspaceFetcher = DefaultHttpWorkspaceFetcher(
            config: config,
            sdk: sdk,
            httpClient: httpClient
        )

        let workspaceManager = WorkspaceManager(
            httpWorkspaceFetcher: httpWorkspaceFetcher,
            repository: DefaultWorkspaceConfigRepository(
                fileStorage: try? DefaultFileStorage(sdkKey: sdkKey)
            )
        )
        compositeSynchronizer.add(synchronizer: workspaceManager)

        // - UserManager
        let cohortFetcher = DefaultUserCohortFetcher(config: config, httpClient: httpClient)
        let targetFetcher = DefaultUserTargetEventsFetcher(config: config, httpClient: httpClient)

        let userManager = DefaultUserManager(
            device: device,
            repository: keyValueRepositoryBySdkKey,
            cohortFetcher: cohortFetcher,
            targetFetcher: targetFetcher,
            clock: SystemClock.shared
        )
        compositeSynchronizer.add(synchronizer: userManager)

        // - SessionManager

        let sessionManager = DefaultSessionManager(
            userManager: userManager,
            keyValueRepository: globalKeyValueRepository,
            sessionTimeout: config.sessionTimeoutInterval
        )
        userManager.addListener(listener: sessionManager)

        // - ScreenManager

        let screenManager = DefaultScreenManager(
            userManager: userManager
        )

        // - EngagementManager

        let engagementManager = EngagementManager(
            userManager: userManager,
            screenManager: screenManager,
            minimumEngagementDuration: 1.0
        )
        screenManager.addListener(listener: engagementManager)

        // - EventProcessor

        let workspaceDatabase = DatabaseHelper.getWorkspaceDatabase(sdkKey: sdkKey)
        let eventRepository = SQLiteEventRepository(database: workspaceDatabase)
        let eventQueue = DispatchQueue(label: "io.hackle.EventQueue", qos: .utility)
        let httpQueue = DispatchQueue(label: "io.hackle.HttpQueue", qos: .utility)
        let appStateManager = DefaultAppStateManager(queue: eventQueue)
        let eventBackoffController = DefaultUserEventBackoffController(userEventRetryInterval: config.eventFlushInterval, clock: SystemClock.shared)

        let eventDispatcher = DefaultUserEventDispatcher(
            eventBaseUrl: config.eventUrl,
            eventQueue: eventQueue,
            eventRepository: eventRepository,
            httpQueue: httpQueue,
            httpClient: httpClient,
            eventBackoffController: eventBackoffController
        )

        let eventPublisher = DefaultUserEventPublisher()
        var eventFilters = [UserEventFilter]()
        var eventDecorators = [UserEventDecorator]()

        let rcEventDedupRepository = UserDefaultsKeyValueRepository.of(suiteName: String(format: storageSuiteNameRemoteConfigEventDedup, sdkKey))
        let exposureEventDedupRepository = UserDefaultsKeyValueRepository.of(suiteName: String(format: storageSuiteNameExposureEventDedup, sdkKey))


        let rcEventDedupDeterminer = RemoteConfigEventDedupDeterminer(
            repository: rcEventDedupRepository,
            dedupInterval: config.exposureEventDedupInterval)

        let exposureEventDedupDeterminer = ExposureEventDedupDeterminer(
            repository: exposureEventDedupRepository,
            dedupInterval: config.exposureEventDedupInterval)

        appStateManager.addListener(listener: rcEventDedupDeterminer)
        appStateManager.addListener(listener: exposureEventDedupDeterminer)

        let dedupDeterminer = DelegatingUserEventDedupDeterminer(determiners: [
            rcEventDedupDeterminer,
            exposureEventDedupDeterminer
        ])
        let dedupEventFilter = DedupUserEventFilter(eventDedupDeterminer: dedupDeterminer)
        eventFilters.append(dedupEventFilter)

        let sessionUserEventDecorator = SessionUserEventDecorator(sessionManager: sessionManager)
        eventDecorators.append(sessionUserEventDecorator)

        if config.mode == .web_view_wrapper {
            eventFilters.append(WebViewWrapperUserEventFilter())
            eventDecorators.append(WebViewWrapperUserEventDecorator())
        }

        let screenUserEventDecorator = ScreenUserEventDecorator(screenManager: screenManager)

        let eventProcessor = DefaultUserEventProcessor(
            eventFilters: eventFilters,
            eventDecorator: eventDecorators,
            eventPublisher: eventPublisher,
            eventQueue: eventQueue,
            eventRepository: eventRepository,
            eventRepositoryMaxSize: HackleConfig.DEFAULT_EVENT_REPOSITORY_MAX_SIZE,
            eventFlushScheduler: scheduler,
            eventFlushInterval: config.eventFlushInterval,
            eventFlushThreshold: config.eventFlushThreshold,
            eventFlushMaxBatchSize: config.eventFlushThreshold * 2 + 1,
            eventDispatcher: eventDispatcher,
            sessionManager: sessionManager,
            userManager: userManager,
            appStateManager: appStateManager,
            screenUserEventDecorator: screenUserEventDecorator,
            eventBackoffController: eventBackoffController
        )

        // - Core

        let abOverrideStorage = HackleUserManualOverrideStorage.create(suiteName: String(format: storageSuiteNameAB, sdkKey))
        let ffOverrideStorage = HackleUserManualOverrideStorage.create(suiteName: String(format: storageSuiteNameFF, sdkKey))
        let inAppMessageHiddenStorage = DefaultInAppMessageHiddenStorage.create(suiteName: String(format: storageSuiteNameIAM, sdkKey))
        let inAppMessageImpressionStorage = DefaultInAppMessageImpressionStorage.create(suiteName: String(format: storageSuiteNameIAMImpression, sdkKey))
        EvaluationContext.shared.register(inAppMessageHiddenStorage)
        EvaluationContext.shared.register(inAppMessageImpressionStorage)

        let core = DefaultHackleCore.create(
            workspaceFetcher: workspaceManager,
            eventProcessor: eventProcessor,
            manualOverrideStorage: DelegatingManualOverrideStorage(storages: [abOverrideStorage, ffOverrideStorage])
        )

        // - AppStateListener

        appStateManager.addListener(listener: pollingSynchronizer)
        appStateManager.addListener(listener: sessionManager)
        appStateManager.addListener(listener: userManager)
        appStateManager.addListener(listener: eventProcessor)

        // - SessionEventTracker

        let sessionEventTracker = SessionEventTracker(
            userManager: userManager,
            core: core
        )
        if config.sessionTracking {
            sessionManager.addListener(listener: sessionEventTracker)
        }

        // - ScreenEventTracker

        let screenEventTracker = ScreenEventTracker(
            userManager: userManager,
            core: core
        )
        screenManager.addListener(listener: screenEventTracker)

        // - EngagementEventTracker

        let engagementEventTracker = EngagementEventTracker(
            userManager: userManager,
            core: core
        )
        engagementManager.addListener(listener: engagementEventTracker)

        // - InAppMessage

        let inAppMessageEventMatcher = DefaultInAppMessageEventMatcher(
            ruleDeterminer: InAppMessageEventTriggerRuleDeterminer(targetMatcher: EvaluationContext.shared.get(TargetMatcher.self)!)
        )
        let inAppMessageDeterminer = DefaultInAppMessageDeterminer(
            workspaceFetcher: workspaceManager,
            eventMatcher: inAppMessageEventMatcher,
            core: core
        )
        let urlHandler = ApplicationUrlHandler()
        let inAppMessageActionHandlerFactory = InAppMessageActionHandlerFactory(handlers: [
            InAppMessageCloseActionHandler(),
            InAppMessageLinkActionHandler(urlHandler: urlHandler),
            InAppMessageLinkAndCloseHandler(urlHandler: urlHandler),
            InAppMessageHiddenActionHandler(clock: SystemClock.shared, storage: inAppMessageHiddenStorage)
        ])
        let inAppMessageEventProcessorFactory = InAppMessageEventProcessorFactory(processors: [
            InAppMessageImpressionEventProcessor(),
            InAppMessageActionEventProcessor(actionHandlerFactory: inAppMessageActionHandlerFactory),
            InAppMessageCloseEventProcessor()
        ])
        let inAppMessageEventHandler = DefaultInAppMessageEventHandler(
            clock: SystemClock.shared,
            eventTracker: DefaultInAppMessageEventTracker(core: core),
            processorFactory: inAppMessageEventProcessorFactory
        )

        let inAppMessageUI = HackleInAppMessageUI(
            eventHandler: inAppMessageEventHandler
        )
        let inAppMessageManager = InAppMessageManager(
            determiner: inAppMessageDeterminer,
            presenter: inAppMessageUI
        )

        if !inAppMessageDisabled(config: config) {
            eventPublisher.addListener(listener: inAppMessageManager)
        }

        // - Push

        let pushTokenRegistry = DefaultPushTokenRegistry.shared
        let pushEventTracker = DefaultPushEventTracker(
            userManager: userManager,
            core: core
        )
        let pushTokenManager = DefaultPushTokenManager(
            repository: keyValueRepositoryBySdkKey,
            userManager: userManager,
            eventTracker: pushEventTracker
        )
        sessionManager.addListener(listener: pushTokenManager)
        pushTokenRegistry.addListener(listener: pushTokenManager)

        // - Notification

        let notificationManager = DefaultNotificationManager(
            core: core,
            dispatchQueue: DispatchQueue(label: "io.hackle.NotificationManager", qos: .utility),
            workspaceFetcher: workspaceManager,
            userManager: userManager,
            repository: DefaultNotificationRepository(
                sharedDatabase: DatabaseHelper.getSharedDatabase()
            )
        )
        NotificationHandler.shared.setNotificationDataReceiver(receiver: notificationManager)

        // - UserExplorer

        let devToolsAPI = DefaultDevToolsAPI(sdk: sdk, url: config.apiUrl, httpClient: httpClient)

        let userExplorer = DefaultHackleUserExplorer(
            core: core,
            userManager: userManager,
            pushTokenManager: pushTokenManager,
            abTestOverrideStorage: abOverrideStorage,
            featureFlagOverrideStorage: ffOverrideStorage,
            devToolsAPI: devToolsAPI
        )

        // - Metrics

        HackleApp.metricConfiguration(
            config: config,
            appStateManager: appStateManager,
            eventQueue: eventQueue,
            httpQueue: httpQueue,
            httpClient: httpClient
        )

        // - Lifecycle

        let lifecycleManager = LifecycleManager.shared
        lifecycleManager.addObserver(observer: ApplicationLifecycleObserver())
        if config.automaticScreenTracking {
            lifecycleManager.addObserver(observer: ViewLifecycleObserver())
            lifecycleManager.addListener(listener: screenManager)
        }
        lifecycleManager.addListener(listener: engagementManager)
        lifecycleManager.addListener(listener: appStateManager)

        let throttleLimiter = ScopingThrottleLimiter(interval: 60, limit: 1, clock: SystemClock.shared)
        let throttler = DefaultThrottler(limiter: throttleLimiter)

        let hackleAppCore = DefaultHackleAppCore(
            core: core,
            eventQueue: eventQueue,
            synchronizer: pollingSynchronizer,
            userManager: userManager,
            workspaceManager: workspaceManager,
            sessionManager: sessionManager,
            screenManager: screenManager,
            eventProcessor: eventProcessor,
            lifecycleManager: lifecycleManager,
            pushTokenRegistry: pushTokenRegistry,
            notificationManager: notificationManager,
            fetchThrottler: throttler,
            device: device,
            inAppMessageUI: inAppMessageUI,
            userExplorer: userExplorer
        )
        let hackleInvocator = DefaultHackleInvocator(hackleAppCore: hackleAppCore)

        return HackleApp(
            hackleAppCore: hackleAppCore,
            mode: config.mode,
            sdk: sdk,
            hackleInvocator: hackleInvocator
        )
    }

    private static func inAppMessageDisabled(config: HackleConfig) -> Bool {
        if let disableInAppMessage = config.extra["$disable_inappmessage"],
           disableInAppMessage == "true" {
            return true
        }

        return false
    }

    private static func metricConfiguration(
        config: HackleConfig,
        appStateManager: DefaultAppStateManager,
        eventQueue: DispatchQueue,
        httpQueue: DispatchQueue,
        httpClient: HttpClient
    ) {
        let monitoringMetricRegistry = MonitoringMetricRegistry(
            monitoringBaseUrl: config.monitoringUrl,
            eventQueue: eventQueue,
            httpQueue: httpQueue,
            httpClient: httpClient
        )

        appStateManager.addListener(listener: monitoringMetricRegistry)
        Metrics.addRegistry(registry: monitoringMetricRegistry)
    }
}
