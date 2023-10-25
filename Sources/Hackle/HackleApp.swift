//
// Created by yong on 2020/12/11.
//

import Foundation
import WebKit

/// Entry point of Hackle Sdk.
@objc public final class HackleApp: NSObject, HackleAppProtocol {

    private let core: HackleCore
    private let eventQueue: DispatchQueue
    private let hackleUserResolver: HackleUserResolver
    private let device: Device
    private let userManager: UserManager
    private let sessionManager: SessionManager
    private let eventProcessor: DefaultUserEventProcessor
    private let notificationObserver: AppNotificationObserver
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
        hackleUserResolver: HackleUserResolver,
        device: Device,
        userManager: UserManager,
        sessionManager: SessionManager,
        eventProcessor: DefaultUserEventProcessor,
        notificationObserver: AppNotificationObserver,
        userExplorer: HackleUserExplorer
    ) {
        self.sdk = sdk
        self.core = core
        self.eventQueue = eventQueue
        self.hackleUserResolver = hackleUserResolver
        self.device = device
        self.userManager = userManager
        self.sessionManager = sessionManager
        self.eventProcessor = eventProcessor
        self.notificationObserver = notificationObserver
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
        userManager.setUser(user: user)
    }

    @objc public func setUserId(userId: String?) {
        userManager.setUserId(userId: userId)
    }

    @objc public func setDeviceId(deviceId: String) {
        userManager.setDeviceId(deviceId: deviceId)
    }

    @objc public func setUserProperty(key: String, value: Any?) {
        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()
        updateUserProperties(operations: operations)
    }

    @objc public func updateUserProperties(operations: PropertyOperations) {
        track(event: operations.toEvent())
        userManager.updateProperties(operations: operations)
    }

    @objc public func resetUser() {
        userManager.resetUser()
        track(event: PropertyOperations.clearAll().toEvent())
    }

    @objc public func variation(experimentKey: Int, defaultVariation: String = "A") -> String {
        variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation).variation
    }

    @objc public func variationDetail(experimentKey: Int, defaultVariation: String = "A") -> Decision {
        variationDetailInternal(experimentKey: experimentKey, user: userManager.currentUser, defaultVariation: defaultVariation)
    }

    private func variationDetailInternal(experimentKey: Int, user: User, defaultVariation: String) -> Decision {
        let sample = TimerSample.start()
        let decision: Decision
        do {
            let hackleUser = hackleUserResolver.resolve(user: user)
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
        allVariationDetailsInternal(user: userManager.currentUser)
    }

    private func allVariationDetailsInternal(user: User) -> [Int: Decision] {
        do {
            let hackleUser = hackleUserResolver.resolve(user: user)
            return try core.experiments(user: hackleUser).associate { experiment, decision in
                (Int(experiment.key), decision)
            }
        } catch let error {
            Log.error("Unexpected error while deciding variations for experiments: \(String(describing: error))")
            return [:]
        }
    }

    @objc public func isFeatureOn(featureKey: Int) -> Bool {
        featureFlagDetailInternal(featureKey: featureKey, user: userManager.currentUser).isOn
    }

    @objc public func featureFlagDetail(featureKey: Int) -> FeatureFlagDecision {
        featureFlagDetailInternal(featureKey: featureKey, user: userManager.currentUser)
    }

    private func featureFlagDetailInternal(featureKey: Int, user: User) -> FeatureFlagDecision {
        let sample = TimerSample.start()
        let decision: FeatureFlagDecision
        do {
            let hackleUser = hackleUserResolver.resolve(user: user)
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
        trackInternal(event: Hackle.event(key: eventKey), user: userManager.currentUser)
    }

    @objc public func track(event: Event) {
        trackInternal(event: event, user: userManager.currentUser)
    }

    private func trackInternal(event: Event, user: User) {
        let hackleUser = hackleUserResolver.resolve(user: user)
        core.track(event: event, user: hackleUser)
    }

    @objc public func remoteConfig() -> HackleRemoteConfig {
        DefaultRemoteConfig(user: nil, app: core, userManager: userManager, userResolver: hackleUserResolver)
    }
    
    @objc public func setWebViewBridge(_ webView: WKWebView, _ uiDelegate: WKUIDelegate? = nil) {
        webView.prepareForHackleWebBridge(app: self, uiDelegate: uiDelegate)
    }

    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    @objc public func variation(experimentKey: Int, userId: String, defaultVariation: String = "A") -> String {
        let updatedUser = userManager.setUser(user: Hackle.user(id: userId))
        return variationDetailInternal(experimentKey: experimentKey, user: updatedUser, defaultVariation: defaultVariation).variation
    }

    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    @objc public func variation(experimentKey: Int, user: User, defaultVariation: String = "A") -> String {
        let updatedUser = userManager.setUser(user: user)
        return variationDetailInternal(experimentKey: experimentKey, user: updatedUser, defaultVariation: defaultVariation).variation
    }

    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    @objc public func variationDetail(experimentKey: Int, userId: String, defaultVariation: String = "A") -> Decision {
        let updatedUser = userManager.setUser(user: Hackle.user(id: userId))
        return variationDetailInternal(experimentKey: experimentKey, user: updatedUser, defaultVariation: defaultVariation)
    }

    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    @objc public func variationDetail(experimentKey: Int, user: User, defaultVariation: String = "A") -> Decision {
        let updatedUser = userManager.setUser(user: user)
        return variationDetailInternal(experimentKey: experimentKey, user: updatedUser, defaultVariation: defaultVariation)
    }

    @available(*, deprecated, message: "Use allVariationDetails() with setUser(user) instead.")
    @objc public func allVariationDetails(user: User) -> [Int: Decision] {
        let updatedUser = userManager.setUser(user: user)
        return allVariationDetailsInternal(user: updatedUser)
    }

    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    @objc public func isFeatureOn(featureKey: Int, userId: String) -> Bool {
        let updatedUser = userManager.setUser(user: Hackle.user(id: userId))
        return featureFlagDetailInternal(featureKey: featureKey, user: updatedUser).isOn
    }

    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    @objc public func isFeatureOn(featureKey: Int, user: User) -> Bool {
        let updatedUser = userManager.setUser(user: user)
        return featureFlagDetailInternal(featureKey: featureKey, user: updatedUser).isOn
    }

    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    @objc public func featureFlagDetail(featureKey: Int, userId: String) -> FeatureFlagDecision {
        let updatedUser = userManager.setUser(user: Hackle.user(id: userId))
        return featureFlagDetailInternal(featureKey: featureKey, user: updatedUser)
    }

    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    @objc public func featureFlagDetail(featureKey: Int, user: User) -> FeatureFlagDecision {
        let updatedUser = userManager.setUser(user: user)
        return featureFlagDetailInternal(featureKey: featureKey, user: updatedUser)
    }

    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    @objc public func track(eventKey: String, userId: String) {
        let updatedUser = userManager.setUser(user: Hackle.user(id: userId))
        trackInternal(event: Hackle.event(key: eventKey), user: updatedUser)
    }

    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    @objc public func track(eventKey: String, user: User) {
        let updatedUser = userManager.setUser(user: user)
        trackInternal(event: Hackle.event(key: eventKey), user: updatedUser)
    }

    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    @objc public func track(event: Event, userId: String) {
        let updatedUser = userManager.setUser(user: Hackle.user(id: userId))
        trackInternal(event: event, user: updatedUser)
    }

    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    @objc public func track(event: Event, user: User) {
        let updatedUser = userManager.setUser(user: user)
        trackInternal(event: event, user: updatedUser)
    }

    @available(*, deprecated, message: "Use remoteConfig() with setUser(user) instead.")
    @objc public func remoteConfig(user: User) -> HackleRemoteConfig {
        DefaultRemoteConfig(user: user, app: core, userManager: userManager, userResolver: hackleUserResolver)
    }
}

extension HackleApp {

    private static let hackleDeviceId = "hackle_device_id"

    func initialize(user: User?, completion: @escaping () -> ()) {
        userManager.initialize(user: user)
        eventQueue.async {
            self.sessionManager.initialize()
            self.eventProcessor.initialize()
            self.core.initialize(completion: completion)
        }
    }

    static func create(sdkKey: String, config: HackleConfig) -> HackleApp {

        let sdk = Sdk.of(sdkKey: sdkKey, config: config)

        let scheduler = Schedulers.dispatch()
        let globalKeyValueRepository = UserDefaultsKeyValueRepository(userDefaults: UserDefaults.standard, suiteName: nil)
        let device = DeviceImpl.create(keyValueRepository: globalKeyValueRepository)
        
        let httpClient = DefaultHttpClient(sdk: sdk)

        // - WorkspaceFetcher

        let httpWorkspaceFetcher = DefaultHttpWorkspaceFetcher(
            sdkBaseUrl: config.sdkUrl,
            httpClient: httpClient
        )

        let workspaceFetcher = PollingWorkspaceFetcher(
            httpWorkspaceFetcher: httpWorkspaceFetcher,
            pollingScheduler: scheduler,
            pollingInterval: config.pollingInterval
        )

        // - EventProcessor

        let databaseHelper = DatabaseHelper(sdkKey: sdkKey)
        let eventRepository = SQLiteEventRepository(databaseHelper: databaseHelper)
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
        let userManager = DefaultUserManager(
            device: device,
            repository: UserDefaultsKeyValueRepository.of(suiteName: "Hackle_\(sdkKey)")
        )
        let sessionManager = DefaultSessionManager(
            userManager: userManager,
            keyValueRepository: globalKeyValueRepository,
            sessionTimeout: config.sessionTimeoutInterval
        )
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
            eventFlushScheduler: Schedulers.dispatch(),
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
            workspaceFetcher: workspaceFetcher,
            eventProcessor: eventProcessor,
            manualOverrideStorage: DelegatingManualOverrideStorage(storages: [abOverrideStorage, ffOverrideStorage])
        )

        // -- NotificationObserver

        let appNotificationObserver = DefaultAppNotificationObserver(eventQueue: eventQueue, appStateManager: appStateManager)
        appNotificationObserver.addListener(listener: workspaceFetcher)
        appNotificationObserver.addListener(listener: sessionManager)
        appNotificationObserver.addListener(listener: userManager)
        appNotificationObserver.addListener(listener: eventProcessor)
        userManager.addListener(listener: sessionManager)

        // -- UserResolver, SessionEventTracker

        let hackleUserResolver = DefaultHackleUserResolver(device: device)
        let sessionEventTracker = SessionEventTracker(
            hackleUserResolver: hackleUserResolver,
            core: core
        )
        sessionManager.addListener(listener: sessionEventTracker)

        // - InAppMessage

        let inAppMessageEventMatcher = DefaultInAppMessageEventMatcher(
            ruleDeterminer: InAppMessageEventTriggerRuleDeterminer(targetMatcher: EvaluationContext.shared.get(TargetMatcher.self)!),
            frequencyCapDeterminer: InAppMessageEventTriggerFrequencyCapDeterminer(storage: inAppMessageImpressionStorage)
        )
        let inAppMessageDeterminer = DefaultInAppMessageDeterminer(
            workspaceFetcher: workspaceFetcher,
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

        // - UserExplorer

        let userExplorer = DefaultHackleUserExplorer(
            core: core,
            userManager: userManager,
            userResolver: hackleUserResolver,
            abTestOverrideStorage: abOverrideStorage,
            featureFlagOverrideStorage: ffOverrideStorage
        )

        // - Metrics

        HackleApp.metricConfiguration(config: config, observer: appNotificationObserver, eventQueue: eventQueue, httpQueue: httpQueue, httpClient: httpClient)

        return HackleApp(
            sdk: sdk,
            core: core,
            eventQueue: eventQueue,
            hackleUserResolver: hackleUserResolver,
            device: device,
            userManager: userManager,
            sessionManager: sessionManager,
            eventProcessor: eventProcessor,
            notificationObserver: appNotificationObserver,
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
