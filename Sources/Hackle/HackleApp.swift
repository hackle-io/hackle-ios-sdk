//
// Created by yong on 2020/12/11.
//

import Foundation
import WebKit

/// Entry point of Hackle Sdk.
@objc public final class HackleApp: NSObject, HackleAppProtocol {

    private let core: HackleCore
    private let eventQueue: DispatchQueue
    private let synchronizer: CompositeSynchronizer
    private let userManager: UserManager
    private let sessionManager: SessionManager
    private let eventProcessor: UserEventProcessor
    private let notificationObserver: AppNotificationObserver
    private let notificationManager: NotificationManager
    private let device: Device
    internal let userExplorer: HackleUserExplorer
    internal let sdk: Sdk

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
        sdk: Sdk,
        core: HackleCore,
        eventQueue: DispatchQueue,
        synchronizer: CompositeSynchronizer,
        userManager: UserManager,
        sessionManager: SessionManager,
        eventProcessor: UserEventProcessor,
        notificationObserver: AppNotificationObserver,
        notificationManager: NotificationManager,
        device: Device,
        userExplorer: HackleUserExplorer
    ) {
        self.sdk = sdk
        self.core = core
        self.eventQueue = eventQueue
        self.synchronizer = synchronizer
        self.userManager = userManager
        self.sessionManager = sessionManager
        self.eventProcessor = eventProcessor
        self.notificationObserver = notificationObserver
        self.notificationManager = notificationManager
        self.device = device
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

    @objc public func setUser(user: User) {
        setUser(user: user, completion: {})
    }

    @objc public func setUser(user: User, completion: @escaping () -> ()) {
        userManager.setUser(user: user)
        synchronizer.syncOnly(type: .cohort, completion: completion)
    }

    @objc public func setUserId(userId: String?) {
        setUserId(userId: userId, completion: {})
    }

    @objc public func setUserId(userId: String?, completion: @escaping () -> ()) {
        userManager.setUserId(userId: userId)
        synchronizer.syncOnly(type: .cohort, completion: completion)
    }

    @objc public func setDeviceId(deviceId: String) {
        setDeviceId(deviceId: deviceId, completion: {})
    }

    @objc public func setDeviceId(deviceId: String, completion: @escaping () -> ()) {
        userManager.setDeviceId(deviceId: deviceId)
        synchronizer.syncOnly(type: .cohort, completion: completion)
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
        userManager.updateProperties(operations: operations)
        completion()
    }

    @objc public func resetUser() {
        resetUser(completion: {})
    }

    @objc public func resetUser(completion: @escaping () -> ()) {
        userManager.resetUser()
        track(event: PropertyOperations.clearAll().toEvent())
        synchronizer.syncOnly(type: .cohort, completion: completion)
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
        notificationManager.setPushToken(deviceToken: deviceToken, timestamp: Date())
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
}

extension HackleApp {

    private static let hackleDeviceId = "hackle_device_id"

    func initialize(user: User?, completion: @escaping () -> ()) {
        userManager.initialize(user: user)
        eventQueue.async {
            self.sessionManager.initialize()
            self.eventProcessor.initialize()
            self.synchronizer.sync(completion: {
                self.notificationManager.flush()
                completion()
            })
        }
    }

    static func create(sdkKey: String, config: HackleConfig) -> HackleApp {

        let sdk = Sdk.of(sdkKey: sdkKey, config: config)

        let scheduler = Schedulers.dispatch()
        let globalKeyValueRepository = UserDefaultsKeyValueRepository(userDefaults: UserDefaults.standard, suiteName: nil)
        let keyValueRepositoryBySdkKey = UserDefaultsKeyValueRepository.of(suiteName: "Hackle_\(sdkKey)")
        let device = DeviceImpl.create(keyValueRepository: globalKeyValueRepository)

        let httpClient = DefaultHttpClient(sdk: sdk)

        // - Synchronizer

        let compositeSynchronizer = DefaultCompositeSynchronizer(
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
            workspaceFile: try? File(directory: sdkKey, filename: "workspace.json")
        )
        compositeSynchronizer.add(type: .workspace, synchronizer: workspaceManager)

        // - UserManager

        let cohortFetcher = DefaultUserCohortFetcher(config: config, httpClient: httpClient)

        let userManager = DefaultUserManager(
            device: device,
            repository: keyValueRepositoryBySdkKey,
            cohortFetcher: cohortFetcher,
            clock: SystemClock.shared
        )
        compositeSynchronizer.add(type: .cohort, synchronizer: userManager)

        // - SessionManager

        let sessionManager = DefaultSessionManager(
            userManager: userManager,
            keyValueRepository: globalKeyValueRepository,
            sessionTimeout: config.sessionTimeoutInterval
        )
        userManager.addListener(listener: sessionManager)

        // - EventProcessor
        let workspaceDatabase = DatabaseHelper.getWorkspaceDatabase(sdkKey: sdkKey)
        let eventRepository = SQLiteEventRepository(database: workspaceDatabase)
        let eventQueue = DispatchQueue(label: "io.hackle.EventQueue", qos: .utility)
        let httpQueue = DispatchQueue(label: "io.hackle.HttpQueue", qos: .utility)

        let eventDispatcher = DefaultUserEventDispatcher(
            eventBaseUrl: config.eventUrl,
            eventQueue: eventQueue,
            eventRepository: eventRepository,
            httpQueue: httpQueue,
            httpClient: httpClient
        )

        let eventPublisher = DefaultUserEventPublisher()

        let dedupDeterminer = DefaultExposureEventDedupDeterminer(
            dedupInterval: config.exposureEventDedupInterval
        )
        let appStateManager = DefaultAppStateManager()
        let eventProcessor = DefaultUserEventProcessor(
            eventDedupDeterminer: dedupDeterminer,
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
            appStateManager: appStateManager
        )

        // - Core

        let abOverrideStorage = HackleUserManualOverrideStorage.create(suiteName: "Hackle_ab_override_\(sdkKey)")
        let ffOverrideStorage = HackleUserManualOverrideStorage.create(suiteName: "Hackle_ff_override_\(sdkKey)")
        let inAppMessageHiddenStorage = DefaultInAppMessageHiddenStorage.create(suiteName: "Hackle_iam_\(sdkKey)")
        let inAppMessageImpressionStorage = DefaultInAppMessageImpressionStorage.create(suiteName: "Hackle_iam_impression_\(sdkKey)")
        EvaluationContext.shared.register(inAppMessageHiddenStorage)

        let core = DefaultHackleCore.create(
            workspaceFetcher: workspaceManager,
            eventProcessor: eventProcessor,
            manualOverrideStorage: DelegatingManualOverrideStorage(storages: [abOverrideStorage, ffOverrideStorage])
        )

        // - NotificationObserver

        let appNotificationObserver = DefaultAppNotificationObserver(eventQueue: eventQueue, appStateManager: appStateManager)
        appNotificationObserver.addListener(listener: pollingSynchronizer)
        appNotificationObserver.addListener(listener: sessionManager)
        appNotificationObserver.addListener(listener: userManager)
        appNotificationObserver.addListener(listener: eventProcessor)

        // - SessionEventTracker

        let sessionEventTracker = SessionEventTracker(
            userManager: userManager,
            core: core
        )
        sessionManager.addListener(listener: sessionEventTracker)

        // - InAppMessage

        let inAppMessageEventMatcher = DefaultInAppMessageEventMatcher(
            ruleDeterminer: InAppMessageEventTriggerRuleDeterminer(targetMatcher: EvaluationContext.shared.get(TargetMatcher.self)!),
            frequencyCapDeterminer: InAppMessageEventTriggerFrequencyCapDeterminer(storage: inAppMessageImpressionStorage)
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
        eventPublisher.addListener(listener: inAppMessageManager)
        
        // - Notification
        let notificationQueue = DispatchQueue(label: "io.hackle.NotificationManager", qos: .utility)
        let notificationManager = DefaultNotificationManager(
            core: core,
            dispatchQueue: notificationQueue,
            workspaceFetcher: workspaceManager,
            userManager: userManager,
            preferences: keyValueRepositoryBySdkKey,
            repository: DefaultNotificationRepository(
                sharedDatabase: DatabaseHelper.getSharedDatabase()
            )
        )
        NotificationHandler.shared.setNotificationDataReceiver(receiver: notificationManager)
        userManager.addListener(listener: notificationManager)

        // - UserExplorer

        let userExplorer = DefaultHackleUserExplorer(
            core: core,
            userManager: userManager,
            notificationManager: notificationManager,
            abTestOverrideStorage: abOverrideStorage,
            featureFlagOverrideStorage: ffOverrideStorage
        )

        // - Metrics

        HackleApp.metricConfiguration(
            config: config,
            observer: appNotificationObserver,
            eventQueue: eventQueue,
            httpQueue: httpQueue,
            httpClient: httpClient
        )

        return HackleApp(
            sdk: sdk,
            core: core,
            eventQueue: eventQueue,
            synchronizer: pollingSynchronizer,
            userManager: userManager,
            sessionManager: sessionManager,
            eventProcessor: eventProcessor,
            notificationObserver: appNotificationObserver,
            notificationManager: notificationManager,
            device: device,
            userExplorer: userExplorer
        )
    }

    private static func metricConfiguration(
        config: HackleConfig,
        observer: DefaultAppNotificationObserver,
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

        observer.addListener(listener: monitoringMetricRegistry)
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
    
    func setUser(user: User)
    func setUserId(userId: String?)
    func setUserProperty(key: String, value: Any?)
    func updateUserProperties(operations: PropertyOperations)
    func resetUser()
    
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
