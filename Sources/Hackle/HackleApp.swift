//
// Created by yong on 2020/12/11.
//

import Foundation
import WebKit

/// Entry point of Hackle SDK.
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

    /// Delegate for handling in-app message events.
    @objc public var inAppMessageDelegate: HackleInAppMessageDelegate? {
        didSet {
            hackleAppCore.setInAppMessageDelegate(inAppMessageDelegate)
        }
    }

    /// The user's device ID.
    ///
    /// - Returns: the current device ID
    @objc public var deviceId: String {
        get {
            hackleAppCore.deviceId
        }
    }

    /// Current session ID.
    ///
    /// - Returns: the current session ID
    @objc public var sessionId: String {
        get {
            hackleAppCore.sessionId
        }
    }

    /// Current user.
    ///
    /// - Returns: the current ``User`` instance
    @objc public var user: User {
        get {
            hackleAppCore.user
        }
    }

    /// Shows the user explorer UI button.
    @objc public func showUserExplorer() {
        hackleAppCore.showUserExplorer()
    }

    /// Hides the user explorer UI button.
    @objc public func hideUserExplorer() {
        hackleAppCore.hideUserExplorer()
    }

    /// Sets or replaces the current user.
    ///
    /// - Parameter user: the ``User`` to set
    @objc public func setUser(user: User) {
        setUser(user: user, completion: {})
    }

    /// Sets or replaces the current user with completion.
    ///
    /// - Parameters:
    ///   - user: the ``User`` to set
    ///   - completion: callback to be executed when the operation is complete
    @objc public func setUser(user: User, completion: @escaping () -> ()) {
        hackleAppCore.setUser(user: user, hackleAppContext: .default, completion: completion)
    }

    /// Sets the userId for the current user.
    ///
    /// - Parameter userId: the userId to set for the user. Can be null to identify an anonymous user
    @objc public func setUserId(userId: String?) {
        setUserId(userId: userId, completion: {})
    }

    /// Sets the userId for the current user with completion.
    ///
    /// - Parameters:
    ///   - userId: the userId to set for the user. Can be null to identify an anonymous user
    ///   - completion: callback to be executed when the operation is complete
    @objc public func setUserId(userId: String?, completion: @escaping () -> ()) {
        hackleAppCore.setUserId(userId: userId, hackleAppContext: .default, completion: completion)
    }

    /// Sets a custom device ID.
    ///
    /// - Parameter deviceId: the custom device ID to set
    @objc public func setDeviceId(deviceId: String) {
        setDeviceId(deviceId: deviceId, completion: {})
    }

    /// Sets a custom device ID with completion.
    ///
    /// - Parameters:
    ///   - deviceId: the custom device ID to set
    ///   - completion: callback to be executed when the operation is complete
    @objc public func setDeviceId(deviceId: String, completion: @escaping () -> ()) {
        hackleAppCore.setDeviceId(deviceId: deviceId, hackleAppContext: .default, completion: completion)
    }

    /// Sets a single user property.
    ///
    /// - Parameters:
    ///   - key: the key of the property
    ///   - value: the value of the property
    @objc public func setUserProperty(key: String, value: Any?) {
        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()
        updateUserProperties(operations: operations)
    }

    /// Sets a single user property with completion.
    ///
    /// - Parameters:
    ///   - key: the key of the property
    ///   - value: the value of the property
    ///   - completion: callback to be executed when the operation is complete
    @objc public func setUserProperty(key: String, value: Any?, completion: @escaping () -> ()) {
        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()
        updateUserProperties(operations: operations, completion: completion)
    }

    /// Updates user properties with a set of operations.
    ///
    /// - Parameter operations: a set of ``PropertyOperations`` to apply to user properties
    @objc public func updateUserProperties(operations: PropertyOperations) {
        updateUserProperties(operations: operations, completion: {})
    }

    /// Updates user properties with a set of operations with completion.
    ///
    /// - Parameters:
    ///   - operations: a set of ``PropertyOperations`` to apply to user properties
    ///   - completion: callback to be executed when the operation is complete
    @objc public func updateUserProperties(operations: PropertyOperations, completion: @escaping () -> ()) {
        hackleAppCore.updateUserProperties(operations: operations, hackleAppContext: .default, completion: completion)
    }

    /// Updates push notification subscription status.
    ///
    /// - Parameter operations: a set of subscription operations to apply
    @objc public func updatePushSubscriptions(operations: HackleSubscriptionOperations) {
        hackleAppCore.updatePushSubscriptions(operations: operations, hackleAppContext: .default)
    }

    /// Updates SMS subscription status.
    ///
    /// - Parameter operations: a set of subscription operations to apply
    @objc public func updateSmsSubscriptions(operations: HackleSubscriptionOperations) {
        hackleAppCore.updateSmsSubscriptions(operations: operations, hackleAppContext: .default)
    }


    /// Updates KakaoTalk subscription status.
    ///
    /// - Parameter operations: a set of subscription operations to apply
    @objc public func updateKakaoSubscriptions(operations: HackleSubscriptionOperations) {
        hackleAppCore.updateKakaoSubscriptions(operations: operations, hackleAppContext: .default)
    }

    /// Resets the current user.
    @objc public func resetUser() {
        resetUser(completion: {})
    }

    /// Resets the current user with completion.
    ///
    /// - Parameter completion: callback to be executed when the operation is complete
    @objc public func resetUser(completion: @escaping () -> ()) {
        hackleAppCore.resetUser(hackleAppContext: .default, completion: completion)
    }

    /// Sets the phone number for the current user.
    ///
    /// - Parameter phoneNumber: the phone number to set
    @objc public func setPhoneNumber(phoneNumber: String) {
        setPhoneNumber(phoneNumber: phoneNumber, completion: {})
    }

    /// Sets the phone number for the current user with completion.
    ///
    /// - Parameters:
    ///   - phoneNumber: the phone number to set
    ///   - completion: callback to be executed when the operation is complete
    @objc public func setPhoneNumber(phoneNumber: String, completion: @escaping () -> ()) {
        hackleAppCore.setPhoneNumber(phoneNumber: phoneNumber, hackleAppContext: .default, completion: completion)
    }

    /// Removes the phone number from the current user.
    @objc public func unsetPhoneNumber() {
        unsetPhoneNumber(completion: {})
    }

    /// Removes the phone number from the current user with completion.
    ///
    /// - Parameter completion: callback to be executed when the operation is complete
    @objc public func unsetPhoneNumber(completion: @escaping () -> ()) {
        hackleAppCore.unsetPhoneNumber(hackleAppContext: .default, completion: completion)
    }

    /// Decide the variation to expose to the user for experiment.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key of the experiment
    ///   - defaultVariation: the default variation of the experiment
    /// - Returns: the decided variation for the user, or defaultVariation
    @objc public func variation(experimentKey: Int, defaultVariation: String = "A") -> String {
        variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation).variation
    }

    /// Decide the variation to expose to the user for experiment and returns an object that describes the way the variation was decided.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key for the experiment
    ///   - defaultVariation: the default variation of the experiment
    /// - Returns: a ``Decision`` object
    @objc public func variationDetail(experimentKey: Int, defaultVariation: String = "A") -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: nil, defaultVariation: defaultVariation, hackleAppContext: .default)
    }

    /// Decide the variations for all experiments and returns a map of decision results.
    ///
    /// - Returns: a dictionary where key is experimentKey and value is ``Decision`` result
    @objc public func allVariationDetails() -> [Int: Decision] {
        hackleAppCore.allVariationDetails(user: nil, hackleAppContext: .default)
    }

    /// Decide whether the feature is turned on to the user.
    ///
    /// - Parameter featureKey: the unique key for the feature
    /// - Returns: True if the feature is on, False if the feature is off
    @objc public func isFeatureOn(featureKey: Int) -> Bool {
        featureFlagDetail(featureKey: featureKey).isOn
    }

    /// Decide whether the feature is turned on to the user and returns an object that describes the way the flag was decided.
    ///
    /// - Parameter featureKey: the unique key for the feature
    /// - Returns: a ``FeatureFlagDecision`` object
    @objc public func featureFlagDetail(featureKey: Int) -> FeatureFlagDecision {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: nil, hackleAppContext: .default)
    }

    /// Records the event that occurred by the user.
    ///
    /// - Parameter eventKey: the unique key of the event that occurred
    @objc public func track(eventKey: String) {
        track(event: Hackle.event(key: eventKey))
    }

    /// Records the event that occurred by the user.
    ///
    /// - Parameter event: the ``Event`` that occurred
    @objc public func track(event: Event) {
        hackleAppCore.track(event: event, user: nil, hackleAppContext: .default)
    }

    /// Returns an instance of Hackle Remote Config.
    ///
    /// - Returns: a ``HackleRemoteConfig`` instance
    @objc public func remoteConfig() -> HackleRemoteConfig {
        DefaultRemoteConfig(hackleAppCore: hackleAppCore, user: nil)
    }

    /// Injects the supplied object into this WebView.
    ///
    /// - Parameters:
    ///   - webView: Target WebView
    ///   - uiDelegate: Optional UI delegate for the WebView
    @objc public func setWebViewBridge(_ webView: WKWebView, _ uiDelegate: WKUIDelegate? = nil) {
        webView.prepareForHackleWebBridge(invocator: invocator(), sdkKey: sdk.key, mode: mode, uiDelegate: uiDelegate)
    }

    /// Returns the HackleInvocator instance.
    ///
    /// - Returns: the ``HackleInvocator`` instance
    @objc public func invocator() -> HackleInvocator {
        return hackleInvocator
    }

    /// Sets the push notification device token.
    ///
    /// - Parameter deviceToken: the device token for push notifications
    @objc public func setPushToken(_ deviceToken: Data) {
        hackleAppCore.setPushToken(deviceToken: deviceToken)
    }

    /// Fetches the latest configuration from the Hackle servers with completion.
    ///
    /// - Parameter completion: callback to be executed when the fetch is complete
    @objc public func fetch(_ completion: @escaping () -> ()) {
        hackleAppCore.fetch(completion: completion)
    }

    /// Sets the current screen for screen tracking.
    ///
    /// - Parameter screen: the ``Screen`` object representing the current screen
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
        ApplicationLifecycleObserver.shared.publishWillEnterForegroundIfNeeded()
    }

    static func create(sdkKey: String, config: HackleConfig) -> HackleApp {
        let clock = SystemClock.shared
        let sdk = Sdk.of(sdkKey: sdkKey, config: config)
        var isIdCreated = false
        
        let globalKeyValueRepository = UserDefaultsKeyValueRepository(userDefaults: UserDefaults.standard, suiteName: nil)
        let keyValueRepositoryBySdkKey = UserDefaultsKeyValueRepository.of(suiteName: String(format: storageSuiteNameDefault, sdkKey))
        let deviceId = DeviceImpl.getDeviceId(keyValueRepository: globalKeyValueRepository) { _ in
            isIdCreated = true
            return UUID().uuidString
        }
        let device = DeviceImpl(deviceId: deviceId)
        let bundleInfo = BundleInfoImpl()
        let applicationInstallDeterminer = ApplicationInstallDeterminer(isDeviceIdCreated: isIdCreated)
        let applicationLifecycleManager = DefaultApplicationLifecycleManager.shared
        
        let httpClient = DefaultHttpClient(sdk: sdk)

        // - Synchronizer

        let compositeSynchronizer = CompositeSynchronizer(
            dispatchQueue: DispatchQueue(label: "io.hackle.DelegatingSynchronizer", attributes: .concurrent)
        )
        let pollingSynchronizer = PollingSynchronizer(
            delegate: compositeSynchronizer,
            scheduler: Schedulers.dispatch(queue: DispatchQueue(label: "io.hackle.scheduler.PollingSynchronizer")),
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
            bundleInfo: bundleInfo,
            repository: keyValueRepositoryBySdkKey,
            cohortFetcher: cohortFetcher,
            targetFetcher: targetFetcher,
            clock: clock
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
        
        applicationLifecycleManager.setDispatchQueue(queue: eventQueue)
        applicationLifecycleManager.addListener(listener: rcEventDedupDeterminer)
        applicationLifecycleManager.addListener(listener: exposureEventDedupDeterminer)

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
            eventFlushScheduler: Schedulers.dispatch(queue: DispatchQueue(label: "io.hackle.scheduler.DefaultUserEventProcessor.flush")),
            eventFlushInterval: config.eventFlushInterval,
            eventFlushThreshold: config.eventFlushThreshold,
            eventFlushMaxBatchSize: config.eventFlushThreshold * 2 + 1,
            eventDispatcher: eventDispatcher,
            sessionManager: sessionManager,
            userManager: userManager,
            applicationLifecycleManager: applicationLifecycleManager,
            screenUserEventDecorator: screenUserEventDecorator,
            eventBackoffController: eventBackoffController
        )

        // - Evaluation Event

        let eventFactory = DefaultUserEventFactory(
            clock: clock
        )

        let evaluationEventRecorder = DefaultEvaluationEventRecorder(
            eventFactory: eventFactory,
            eventProcessor: eventProcessor
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
            eventFactory: eventFactory,
            eventProcessor: eventProcessor,
            manualOverrideStorage: DelegatingManualOverrideStorage(storages: [abOverrideStorage, ffOverrideStorage])
        )

        // - ApplicationLifecycleListener

        applicationLifecycleManager.addListener(listener: pollingSynchronizer)
        applicationLifecycleManager.addListener(listener: sessionManager)
        applicationLifecycleManager.addListener(listener: userManager)
        applicationLifecycleManager.addListener(listener: eventProcessor)
        
        // - ApplicationInstallStateManager
        
        let applicationInstallStateManager = ApplicationInstallStateManager(
            keyValueRepository: globalKeyValueRepository,
            applicationInstallDeterminer:
                applicationInstallDeterminer,
            bundleInfo: bundleInfo,
            clock: clock
        )

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
        
        // - ApplicationEventTracker
        
        let applicationEventTracker = ApplicationEventTracker(
            userManager: userManager,
            core: core
        )
        
        applicationLifecycleManager.addListener(listener: applicationEventTracker)
        applicationInstallStateManager.addListener(listener: applicationEventTracker)

        // - InAppMessage

        let inAppMessageEventTracker = DefaultInAppMessageEventTracker(
            core: core
        )
        let urlHandler = ApplicationUrlHandler()
        let inAppMessageActionHandlerFactory = InAppMessageActionHandlerFactory(handlers: [
            InAppMessageCloseActionHandler(),
            InAppMessageLinkActionHandler(urlHandler: urlHandler),
            InAppMessageLinkAndCloseHandler(urlHandler: urlHandler),
            InAppMessageHiddenActionHandler(clock: clock, storage: inAppMessageHiddenStorage)
        ])
        let inAppMessageEventProcessorFactory = InAppMessageEventProcessorFactory(processors: [
            InAppMessageImpressionEventProcessor(),
            InAppMessageActionEventProcessor(actionHandlerFactory: inAppMessageActionHandlerFactory),
            InAppMessageCloseEventProcessor()
        ])
        let inAppMessageEventHandler = DefaultInAppMessageEventHandler(
            clock: clock,
            eventTracker: inAppMessageEventTracker,
            processorFactory: inAppMessageEventProcessorFactory
        )
        let inAppMessageUI = HackleInAppMessageUI(
            eventHandler: inAppMessageEventHandler
        )

        let inAppMessageRecorder = DefaultInAppMessageRecorder(
            storage: inAppMessageImpressionStorage
        )
        let inAppMessagePresentProcessor = DefaultInAppMessagePresentProcessor(
            presenter: inAppMessageUI,
            recorder: inAppMessageRecorder
        )


        let inAppMessageExperimentEvaluator = InAppMessageExperimentEvaluator(
            evaluator: EvaluationContext.shared.get(Evaluator.self)!
        )
        let inAppMessageLayoutEvaluator = InAppMessageLayoutEvaluator(
            experimentEvaluator: inAppMessageExperimentEvaluator,
            selector: InAppMessageLayoutSelector(),
            eventRecorder: evaluationEventRecorder
        )
        let inAppMessageEligibilityFlowFactory = DefaultInAppMessageEligibilityFlowFactory(
            context: EvaluationContext.shared,
            layoutEvaluator: inAppMessageLayoutEvaluator
        )

        let inAppMessageEvaluateProcessor = DefaultInAppMessageEvaluateProcessor(
            core: core,
            flowFactory: inAppMessageEligibilityFlowFactory,
            eventRecorder: evaluationEventRecorder
        )
        let inAppMessageIdentifierChecker = DefaultInAppMessageIdentifierChecker()
        let inAppMessageLayoutResolver = DefaultInAppMessageLayoutResolver(
            core: core,
            layoutEvaluator: inAppMessageLayoutEvaluator
        )

        let inAppMessageDeliverProcessor = DefaultInAppMessageDeliverProcessor(
            workspaceFetcher: workspaceManager,
            userManager: userManager,
            identifierChecker: inAppMessageIdentifierChecker,
            layoutResolver: inAppMessageLayoutResolver,
            evaluateProcessor: inAppMessageEvaluateProcessor,
            presentProcessor: inAppMessagePresentProcessor
        )

        let inAppMessageDelayScheduler = DefaultInAppMessageDelayScheduler(
            clock: clock,
            scheduler: Schedulers.dispatch(queue: DispatchQueue(label: "io.hackle.scheduler.DefaultInAppMessageDelayScheduler"))
        )
        let inAppMessageDelayManager = DefaultInAppMessageDelayManager(
            scheduler: inAppMessageDelayScheduler
        )

        let inAppMessageSchedulerFactory = DefaultInAppMessageSchedulerFactory(schedulers: [
            TriggeredInAppMessageScheduler(deliverProcessor: inAppMessageDeliverProcessor, delayManager: inAppMessageDelayManager),
            DelayedInAppMessageScheduler(deliverProcessor: inAppMessageDeliverProcessor, delayManager: inAppMessageDelayManager),
        ])
        let inAppMessageScheduleProcessor = DefaultInAppMessageScheduleProcessor(
            actionDeterminer: DefaultInAppMessageScheduleActionDeterminer(),
            schedulerFactory: inAppMessageSchedulerFactory
        )
        inAppMessageDelayScheduler.setListener(listsner: inAppMessageScheduleProcessor)

        let inAppMessageTriggerEventMatcher = DefaultInAppMessageTriggerEventMatcher(
            targetMatcher: EvaluationContext.shared.get(TargetMatcher.self)!
        )
        let inAppMessageTriggerDeterminer = DefaultInAppMessageTriggerDeterminer(
            workspaceFetcher: workspaceManager,
            eventMatcher: inAppMessageTriggerEventMatcher,
            evaluateProcessor: inAppMessageEvaluateProcessor
        )
        let inAppMessageTriggerHandler = DefaultInAppMessageTriggerHandler(
            scheduleProcessor: inAppMessageScheduleProcessor
        )
        let inAppMessageTriggerProcessor = DefaultInAppMessageTriggerProcessor(
            determiner: inAppMessageTriggerDeterminer,
            handler: inAppMessageTriggerHandler
        )

        let inAppMessageResetProcessor = DefaultInAppMessageResetProcessor(
            identifierChecker: inAppMessageIdentifierChecker,
            delayManager: inAppMessageDelayManager
        )

        let inAppMessageManager = InAppMessageManager(
            triggerProcessor: inAppMessageTriggerProcessor,
            resetProcessor: inAppMessageResetProcessor
        )

        if !inAppMessageDisabled(config: config) {
            eventPublisher.addListener(listener: inAppMessageManager)
            userManager.addListener(listener: inAppMessageManager)
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
            applicationLifecycleManager: applicationLifecycleManager,
            eventQueue: eventQueue,
            httpQueue: httpQueue,
            httpClient: httpClient
        )

        // - ViewLifecycle

        let viewLifecycleManager = ViewLifecycleManager.shared
        if config.automaticScreenTracking {
            viewLifecycleManager.addObserver(observer: ViewLifecycleObserver())
            viewLifecycleManager.addListener(listener: screenManager)
        }
        viewLifecycleManager.addListener(listener: engagementManager)
        viewLifecycleManager.setDispatchQueue(queue: eventQueue)
        
        // - ApplicationLifecycleObserve
        let applicationLifecycleObserver = ApplicationLifecycleObserver.shared
        applicationLifecycleObserver.addPublisher(publisher: applicationLifecycleManager)
        applicationLifecycleObserver.addPublisher(publisher: viewLifecycleManager)
        

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
            pushTokenRegistry: pushTokenRegistry,
            notificationManager: notificationManager,
            fetchThrottler: throttler,
            device: device,
            inAppMessageUI: inAppMessageUI,
            applicationInstallStateManager: applicationInstallStateManager,
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
        applicationLifecycleManager: ApplicationLifecycleManager,
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

        applicationLifecycleManager.addListener(listener: monitoringMetricRegistry)
        Metrics.addRegistry(registry: monitoringMetricRegistry)
    }
}
