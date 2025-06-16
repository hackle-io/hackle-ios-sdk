//
// Created by yong on 2020/12/11.
//

import Foundation
import WebKit

/// Entry point of Hackle Sdk.
@objc public final class HackleApp: NSObject, HackleAppProtocol {
    private let core: HackleCore
    private let eventQueue: DispatchQueue
    private let synchronizer: Synchronizer
    private let userManager: UserManager
    private let workspaceManager: WorkspaceManager
    private let sessionManager: SessionManager
    private let eventProcessor: UserEventProcessor
    private let lifecycleManager: LifecycleManager
    private let pushTokenRegistry: PushTokenRegistry
    private let notificationManager: NotificationManager
    private let piiEventManager: PIIEventManager
    private let fetchThrottler: Throttler
    private let device: Device
    private let inAppMessageUI: HackleInAppMessageUI

    internal let userExplorer: HackleUserExplorer
    internal let sdk: Sdk
    internal let mode: HackleAppMode

    @objc public var inAppMessageDelegate: HackleInAppMessageDelegate? {
        didSet {
            self.inAppMessageUI.delegate = inAppMessageDelegate
        }
    }

    @objc public var deviceId: String {
        get {
            device.id
        }
    }

    @objc public var sessionId: String {
        get {
            sessionManager.requiredSession.id
        }
    }

    @objc public var user: User {
        get {
            userManager.currentUser
        }
    }

    init(
        mode: HackleAppMode,
        sdk: Sdk,
        core: HackleCore,
        eventQueue: DispatchQueue,
        synchronizer: Synchronizer,
        userManager: UserManager,
        workspaceManager: WorkspaceManager,
        sessionManager: SessionManager,
        eventProcessor: UserEventProcessor,
        lifecycleManager: LifecycleManager,
        pushTokenRegistry: PushTokenRegistry,
        notificationManager: NotificationManager,
        piiEventManager: PIIEventManager,
        fetchThrottler: Throttler,
        device: Device,
        inAppMessageUI: HackleInAppMessageUI,
        userExplorer: HackleUserExplorer
    ) {
        self.mode = mode
        self.sdk = sdk
        self.core = core
        self.eventQueue = eventQueue
        self.synchronizer = synchronizer
        self.userManager = userManager
        self.workspaceManager = workspaceManager
        self.sessionManager = sessionManager
        self.eventProcessor = eventProcessor
        self.lifecycleManager = lifecycleManager
        self.pushTokenRegistry = pushTokenRegistry
        self.notificationManager = notificationManager
        self.piiEventManager = piiEventManager
        self.fetchThrottler = fetchThrottler
        self.device = device
        self.inAppMessageUI = inAppMessageUI
        self.userExplorer = userExplorer
        super.init()
    }

    private var view: HackleUserExplorerView? = nil

    @objc public func showUserExplorer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            if self.view == nil {
                self.view = HackleUserExplorerView()
            }
            self.view?.attach()
        }
        Metrics.counter(name: "user.explorer.show").increment()
    }

    @objc public func hideUserExplorer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.view?.detach()
        }
    }

    @objc public func setUser(user: User) {
        setUser(user: user, completion: {})
    }

    @objc public func setUser(user: User, completion: @escaping () -> ()) {
        let updated = userManager.setUser(user: user)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    @objc public func setUserId(userId: String?) {
        setUserId(userId: userId, completion: {})
    }

    @objc public func setUserId(userId: String?, completion: @escaping () -> ()) {
        let updated = userManager.setUserId(userId: userId)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    @objc public func setDeviceId(deviceId: String) {
        setDeviceId(deviceId: deviceId, completion: {})
    }

    @objc public func setDeviceId(deviceId: String, completion: @escaping () -> ()) {
        let updated = userManager.setDeviceId(deviceId: deviceId)
        userManager.syncIfNeeded(updated: updated, completion: completion)
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
        track(event: operations.toEvent())
        // Call flush to immediately update the property.
        eventProcessor.flush()
        userManager.updateProperties(operations: operations)
        completion()
    }

    @objc public func resetUser() {
        resetUser(completion: {})
    }

    @objc public func resetUser(completion: @escaping () -> ()) {
        let updated = userManager.resetUser()
        track(event: PropertyOperations.clearAll().toEvent())
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    @objc public func setPhoneNumber(phoneNumber: String) {
        setPhoneNumber(phoneNumber: phoneNumber, completion: {})
    }

    @objc public func setPhoneNumber(phoneNumber: String, completion: @escaping () -> ()) {
        piiEventManager.setPhoneNumber(phoneNumber: PhoneNumber.create(phoneNumber: phoneNumber), timestamp: Date())
        eventProcessor.flush()
        completion()
    }
    
    @objc public func unsetPhoneNumber() {
        unsetPhoneNumber(completion: {})
    }
    
    @objc public func unsetPhoneNumber(completion: @escaping () -> ()) {
        piiEventManager.unsetPhoneNumber(timestamp: Date())
        eventProcessor.flush()
        completion()
    }
    
    @objc public func variation(experimentKey: Int, defaultVariation: String = "A") -> String {
        variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation).variation
    }

    @objc public func variationDetail(experimentKey: Int, defaultVariation: String = "A") -> Decision {
        variationDetailInternal(experimentKey: experimentKey, user: nil, defaultVariation: defaultVariation)
    }

    private func variationDetailInternal(experimentKey: Int, user: User?, defaultVariation: String) -> Decision {
        let sample = TimerSample.start()
        let decision: Decision
        do {
            let hackleUser = userManager.resolve(user: user)
            decision = try core.experiment(
                experimentKey: Int64(experimentKey),
                user: hackleUser,
                defaultVariationKey: defaultVariation
            )
        } catch let error {
            Log.error("Unexpected error while deciding variation for experiment[\(experimentKey)]: \(String(describing: error))")
            decision = Decision.of(experiment: nil, variation: defaultVariation, reason: DecisionReason.EXCEPTION)
        }
        DecisionMetrics.experiment(sample: sample, key: experimentKey, decision: decision)
        return decision
    }

    @objc public func allVariationDetails() -> [Int: Decision] {
        allVariationDetailsInternal(user: nil)
    }

    private func allVariationDetailsInternal(user: User?) -> [Int: Decision] {
        do {
            let hackleUser = userManager.resolve(user: user)
            return try core.experiments(user: hackleUser).associate { experiment, decision in
                (Int(experiment.key), decision)
            }
        } catch let error {
            Log.error("Unexpected error while deciding variations for experiments: \(String(describing: error))")
            return [:]
        }
    }

    @objc public func isFeatureOn(featureKey: Int) -> Bool {
        featureFlagDetail(featureKey: featureKey).isOn
    }

    @objc public func featureFlagDetail(featureKey: Int) -> FeatureFlagDecision {
        featureFlagDetailInternal(featureKey: featureKey, user: nil)
    }

    private func featureFlagDetailInternal(featureKey: Int, user: User?) -> FeatureFlagDecision {
        let sample = TimerSample.start()
        let decision: FeatureFlagDecision
        do {
            let hackleUser = userManager.resolve(user: user)
            decision = try core.featureFlag(
                featureKey: Int64(featureKey),
                user: hackleUser
            )
        } catch {
            Log.error("Unexpected error while deciding feature flag[\(featureKey)]: \(String(describing: error))")
            decision = FeatureFlagDecision.off(featureFlag: nil, reason: DecisionReason.EXCEPTION)
        }
        DecisionMetrics.featureFlag(sample: sample, key: featureKey, decision: decision)
        return decision
    }

    @objc public func track(eventKey: String) {
        track(event: Hackle.event(key: eventKey))
    }

    @objc public func track(event: Event) {
        trackInternal(event: event, user: nil)
    }

    private func trackInternal(event: Event, user: User?) {
        let hackleUser = userManager.resolve(user: user)
        core.track(event: event, user: hackleUser)
    }

    @objc public func remoteConfig() -> HackleRemoteConfig {
        DefaultRemoteConfig(user: nil, app: core, userManager: userManager)
    }

    @objc public func setWebViewBridge(_ webView: WKWebView, _ uiDelegate: WKUIDelegate? = nil) {
        webView.prepareForHackleWebBridge(app: self, uiDelegate: uiDelegate)
    }

    @objc public func setPushToken(_ deviceToken: Data) {
        pushTokenRegistry.register(token: PushToken.of(value: deviceToken), timestamp: Date())
    }

    @objc public func fetch(_ completion: @escaping () -> ()) {
        fetchThrottler.execute(
            accept: {
                self.synchronizer.sync(completion: completion)
            },
            reject: {
                Log.debug("Too many quick fetch requests")
                completion()
            }
        )
    }

    @objc public func updatePushSubscriptionStatus(_ subscriptionStatus: HackleMarketingSubscriptionStatus) {
        let operations = HackleMarketingSubscriptionOperations.builder()
            .global(subscriptionStatus)
            .build()
        track(event: operations.toPushSubscriptionEvent())
        eventProcessor.flush()
    }
    
    @objc public func updateSmsSubscriptionStatus(_ subscriptionStatus: HackleMarketingSubscriptionStatus) {
        let operations = HackleMarketingSubscriptionOperations.builder()
            .global(subscriptionStatus)
            .build()
        track(event: operations.toSmsSubscriptionEvent())
        eventProcessor.flush()
    }
    
    @objc public func updateKakaoSubscriptionStatus(_ subscriptionStatus: HackleMarketingSubscriptionStatus) {
        let operations = HackleMarketingSubscriptionOperations.builder()
            .global(subscriptionStatus)
            .build()
        track(event: operations.toKakaoSubscriptionEvent())
        eventProcessor.flush()
    }

    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    @objc public func variation(experimentKey: Int, userId: String, defaultVariation: String = "A") -> String {
        variationDetailInternal(experimentKey: experimentKey, user: Hackle.user(id: userId), defaultVariation: defaultVariation).variation
    }

    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    @objc public func variation(experimentKey: Int, user: User, defaultVariation: String = "A") -> String {
        variationDetailInternal(experimentKey: experimentKey, user: user, defaultVariation: defaultVariation).variation
    }

    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    @objc public func variationDetail(experimentKey: Int, userId: String, defaultVariation: String = "A") -> Decision {
        variationDetailInternal(experimentKey: experimentKey, user: Hackle.user(id: userId), defaultVariation: defaultVariation)
    }

    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    @objc public func variationDetail(experimentKey: Int, user: User, defaultVariation: String = "A") -> Decision {
        variationDetailInternal(experimentKey: experimentKey, user: user, defaultVariation: defaultVariation)
    }

    @available(*, deprecated, message: "Use allVariationDetails() with setUser(user) instead.")
    @objc public func allVariationDetails(user: User) -> [Int: Decision] {
        allVariationDetailsInternal(user: user)
    }

    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    @objc public func isFeatureOn(featureKey: Int, userId: String) -> Bool {
        featureFlagDetailInternal(featureKey: featureKey, user: Hackle.user(id: userId)).isOn
    }

    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    @objc public func isFeatureOn(featureKey: Int, user: User) -> Bool {
        featureFlagDetailInternal(featureKey: featureKey, user: user).isOn
    }

    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    @objc public func featureFlagDetail(featureKey: Int, userId: String) -> FeatureFlagDecision {
        featureFlagDetailInternal(featureKey: featureKey, user: Hackle.user(id: userId))
    }

    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    @objc public func featureFlagDetail(featureKey: Int, user: User) -> FeatureFlagDecision {
        featureFlagDetailInternal(featureKey: featureKey, user: user)
    }

    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    @objc public func track(eventKey: String, userId: String) {
        trackInternal(event: Hackle.event(key: eventKey), user: Hackle.user(id: userId))
    }

    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    @objc public func track(eventKey: String, user: User) {
        trackInternal(event: Hackle.event(key: eventKey), user: user)
    }

    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    @objc public func track(event: Event, userId: String) {
        trackInternal(event: event, user: Hackle.user(id: userId))
    }

    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    @objc public func track(event: Event, user: User) {
        trackInternal(event: event, user: user)
    }

    @available(*, deprecated, message: "Use remoteConfig() with setUser(user) instead.")
    @objc public func remoteConfig(user: User) -> HackleRemoteConfig {
        DefaultRemoteConfig(user: user, app: core, userManager: userManager)
    }
    
    @available(*, deprecated, message: "Use updatePushSubscriptionStatus(subscriptionStatus) instead.")
    public func updatePushSubscriptionStatus(status: HacklePushSubscriptionStatus) {
        let operations = HacklePushSubscriptionOperations.builder()
            .global(status)
            .build()
        track(event: operations.toEvent())
        eventProcessor.flush()
    }
}

extension HackleApp {
    private static let hackleDeviceId = "hackle_device_id"

    func initialize(user: User?, completion: @escaping () -> ()) {
        lifecycleManager.initialize()
        userManager.initialize(user: user)
        eventQueue.async { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            self.initialize(completion: completion)
        }
    }

    private func initialize(completion: @escaping () -> ()) {
        workspaceManager.initialize()
        sessionManager.initialize()
        eventProcessor.initialize()
        synchronizer.sync(completion: { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            self.pushTokenRegistry.flush()
            self.notificationManager.flush()
            completion()
        })
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

        let eventDispatcher = DefaultUserEventDispatcher(
            eventBaseUrl: config.eventUrl,
            eventQueue: eventQueue,
            eventRepository: eventRepository,
            httpQueue: httpQueue,
            httpClient: httpClient
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
            screenUserEventDecorator: screenUserEventDecorator
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
            InAppMessageImpressionEventProcessor(impressionStorage: inAppMessageImpressionStorage),
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
        
        // - PII
        
        let piiEventManager = DefaultPIIEventManager(
            userManager: userManager,
            core: core
        )
            

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

        return HackleApp(
            mode: config.mode,
            sdk: sdk,
            core: core,
            eventQueue: eventQueue,
            synchronizer: pollingSynchronizer,
            userManager: userManager,
            workspaceManager: workspaceManager,
            sessionManager: sessionManager,
            eventProcessor: eventProcessor,
            lifecycleManager: lifecycleManager,
            pushTokenRegistry: pushTokenRegistry,
            notificationManager: notificationManager,
            piiEventManager: piiEventManager,
            fetchThrottler: throttler,
            device: device,
            inAppMessageUI: inAppMessageUI,
            userExplorer: userExplorer
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

protocol HackleAppProtocol: AnyObject {
    var sdk: Sdk { get }
    var deviceId: String { get }
    func setDeviceId(deviceId: String)

    var sessionId: String { get }
    var user: User { get }

    func showUserExplorer()
    func hideUserExplorer()

    func setUser(user: User)
    func setUserId(userId: String?)
    func setUserProperty(key: String, value: Any?)
    func updateUserProperties(operations: PropertyOperations)
    func resetUser()
    
    func setPhoneNumber(phoneNumber: String)
    func unsetPhoneNumber()

    func variation(experimentKey: Int, defaultVariation: String) -> String
    func variationDetail(experimentKey: Int, defaultVariation: String) -> Decision

    func allVariationDetails() -> [Int: Decision]

    func isFeatureOn(featureKey: Int) -> Bool
    func featureFlagDetail(featureKey: Int) -> FeatureFlagDecision

    func track(eventKey: String)
    func track(event: Event)

    func remoteConfig() -> HackleRemoteConfig

    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    func variation(experimentKey: Int, userId: String, defaultVariation: String) -> String
    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    func variation(experimentKey: Int, user: User, defaultVariation: String) -> String
    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    func variationDetail(experimentKey: Int, userId: String, defaultVariation: String) -> Decision
    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    func variationDetail(experimentKey: Int, user: User, defaultVariation: String) -> Decision

    @available(*, deprecated, message: "Use allVariationDetails() with setUser(user) instead.")
    func allVariationDetails(user: User) -> [Int: Decision]

    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    func isFeatureOn(featureKey: Int, userId: String) -> Bool
    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    func isFeatureOn(featureKey: Int, user: User) -> Bool
    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    func featureFlagDetail(featureKey: Int, userId: String) -> FeatureFlagDecision
    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    func featureFlagDetail(featureKey: Int, user: User) -> FeatureFlagDecision

    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    func track(eventKey: String, userId: String)
    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    func track(eventKey: String, user: User)
    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    func track(event: Event, userId: String)
    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    func track(event: Event, user: User)

    @available(*, deprecated, message: "Use remoteConfig() with setUser(user) instead.")
    func remoteConfig(user: User) -> HackleRemoteConfig
}
