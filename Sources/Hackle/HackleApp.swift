//

import Foundation
import UIKit
import WebKit

/// Entry point of Hackle SDK.
@objc public final class HackleApp: NSObject {
    let hackleAppCore: HackleAppCore
    let sdk: Sdk
    let config: HackleConfig
    let hackleInvocator: HackleInvocator
    private let completionQueue = DispatchQueue(label: "io.hackle.HackleApp.CompletionQueue")

    init(
        hackleAppCore: HackleAppCore,
        sdk: Sdk,
        config: HackleConfig,
        hackleInvocator: HackleInvocator
    ) {
        self.hackleAppCore = hackleAppCore
        self.sdk = sdk
        self.config = config
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
        hackleAppCore.deviceId
    }

    /// Current session ID.
    ///
    /// - Returns: the current session ID
    @objc public var sessionId: String {
        hackleAppCore.sessionId
    }

    /// Current user.
    ///
    /// - Returns: the current ``User`` instance
    @objc public var user: User {
        hackleAppCore.user
    }

    /// Whether opt-out tracking is currently enabled.
    /// When true, all event tracking is blocked.
    @objc public var isOptOutTracking: Bool {
        hackleAppCore.isOptOutTracking
    }

    @MainActor
    @objc public var displayedInAppMessageView: HackleInAppMessageView? {
        hackleAppCore.currentInAppMessageView
    }

    /// Sets whether opt-out tracking is enabled.
    ///
    /// When opt-out is enabled (true), all event tracking will be blocked.
    /// When switching from opt-in to opt-out, a best-effort flush of any
    /// pending events will be attempted before blocking begins.
    ///
    /// This setting is not persisted across app restarts.
    /// On each launch, the opt-out state is determined solely by `HackleConfig.optOutTracking`.
    ///
    /// - Parameter optOut: true to opt out of all event tracking, false to opt back in
    @objc public func setOptOutTracking(optOut: Bool) {
        hackleAppCore.setOptOutTracking(optOut: optOut)
    }

    /// Shows the user explorer UI button.
    @objc public func showUserExplorer() {
        hackleAppCore.showUserExplorer()
    }

    /// Hides the user explorer UI button.
    @objc public func hideUserExplorer() {
        hackleAppCore.hideUserExplorer()
    }

    /// Sets or replaces the current user with completion.
    ///
    /// - Parameters:
    ///   - user: the ``User`` to set
    ///   - completion: callback to be executed when the operation is complete
    @preconcurrency @objc public func setUser(user: User, completion: @escaping @Sendable () -> ()) {
        hackleAppCore.setUser(user: user, hackleAppContext: .default)
            .onComplete(queue: completionQueue, completion)
    }

    /// Sets the userId for the current user with completion.
    ///
    /// - Parameters:
    ///   - userId: the userId to set for the user. Can be null to identify an anonymous user
    ///   - completion: callback to be executed when the operation is complete
    @preconcurrency @objc public func setUserId(userId: String?, completion: @escaping @Sendable () -> ()) {
        hackleAppCore.setUserId(userId: userId, hackleAppContext: .default)
            .onComplete(queue: completionQueue, completion)
    }

    /// Sets a custom device ID with completion.
    ///
    /// - Parameters:
    ///   - deviceId: the custom device ID to set
    ///   - completion: callback to be executed when the operation is complete
    @preconcurrency @objc public func setDeviceId(deviceId: String, completion: @escaping @Sendable () -> ()) {
        hackleAppCore.setDeviceId(deviceId: deviceId, hackleAppContext: .default)
            .onComplete(queue: completionQueue, completion)
    }

    /// Sets a single user property with completion.
    ///
    /// - Parameters:
    ///   - key: the key of the property
    ///   - value: the value of the property
    ///   - completion: callback to be executed when the operation is complete
    @available(*, deprecated, message: "Use updateUserProperties(operations:completion:) instead.")
    @preconcurrency @objc public func setUserProperty(key: String, value: Any?, completion: @escaping @Sendable () -> ()) {
        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()
        updateUserProperties(operations: operations, completion: completion)
    }

    /// Updates user properties with a set of operations with completion.
    ///
    /// - Parameters:
    ///   - operations: a set of ``PropertyOperations`` to apply to user properties
    ///   - completion: callback to be executed when the operation is complete
    @preconcurrency @objc public func updateUserProperties(operations: PropertyOperations, completion: @escaping @Sendable () -> ()) {
        hackleAppCore.updateUserProperties(operations: operations, hackleAppContext: .default)
            .onComplete(queue: completionQueue, completion)
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

    /// Resets the current user with completion.
    ///
    /// - Parameter completion: callback to be executed when the operation is complete
    @preconcurrency @objc public func resetUser(completion: @escaping @Sendable () -> ()) {
        hackleAppCore.resetUser(hackleAppContext: .default)
            .onComplete(queue: completionQueue, completion)
    }

    /// Sets the phone number for the current user with completion.
    ///
    /// - Parameters:
    ///   - phoneNumber: the phone number to set
    ///   - completion: callback to be executed when the operation is complete
    @preconcurrency @objc public func setPhoneNumber(phoneNumber: String, completion: @escaping @Sendable () -> ()) {
        hackleAppCore.setPhoneNumber(phoneNumber: phoneNumber, hackleAppContext: .default)
        completionQueue.async {
            completion()
        }
    }

    /// Removes the phone number from the current user with completion.
    ///
    /// - Parameter completion: callback to be executed when the operation is complete
    @preconcurrency @objc public func unsetPhoneNumber(completion: @escaping @Sendable () -> ()) {
        hackleAppCore.unsetPhoneNumber(hackleAppContext: .default)
        completionQueue.async {
            completion()
        }
    }

    /// Decide the variation to expose to the user for experiment.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key of the experiment
    /// - Returns: the decided variation for the user, or `"A"` if the experiment cannot be decided
    @objc public func variation(experimentKey: Int) -> String {
        variationDetail(experimentKey: experimentKey).variation
    }

    /// Decide the variation to expose to the user for experiment and returns an object that describes the way the variation was decided.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key for the experiment
    /// - Returns: a ``Decision`` object
    @objc public func variationDetail(experimentKey: Int) -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, hackleAppContext: .default)
    }

    /// Decide the variations for all experiments and returns a map of decision results.
    ///
    /// - Returns: a dictionary where key is experimentKey and value is ``Decision`` result
    @objc public func allVariationDetails() -> [Int: Decision] {
        hackleAppCore.allVariationDetails(hackleAppContext: .default)
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
        hackleAppCore.featureFlagDetail(featureKey: featureKey, hackleAppContext: .default)
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
        hackleAppCore.track(event: event, hackleAppContext: .default)
    }

    /// Returns an instance of Hackle Remote Config.
    ///
    /// - Returns: a ``HackleRemoteConfig`` instance
    @objc public func remoteConfig() -> HackleRemoteConfig {
        DefaultRemoteConfig(hackleAppCore: hackleAppCore)
    }

    /// Injects the supplied object into this WebView.
    ///
    /// - Parameters:
    ///   - webView: The target WKWebView instance to integrate with Hackle SDK
    ///   - uiDelegate: Optional UI delegate for the WebView. If not provided, the WebView's existing delegate will be used
    ///   - webViewConfig: Configuration for WebView integration behavior. Defaults to ``HackleWebViewConfig/DEFAULT``
    @MainActor @objc public func setWebViewBridge(_ webView: WKWebView, _ uiDelegate: WKUIDelegate? = nil, _ webViewConfig: HackleWebViewConfig = HackleWebViewConfig.DEFAULT) {
        let javascriptBridge = HackleJavascriptBridge(invocator: invocator(), sdkKey: sdk.key, mode: config.appMode, webViewConfig: webViewConfig)
        javascriptBridge.apply(to: webView, uiDelegate: uiDelegate)
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
    @preconcurrency @objc public func fetch(_ completion: @escaping @Sendable () -> ()) {
        hackleAppCore.fetch()
            .onComplete(queue: completionQueue, completion)
    }

    /// Sets the current screen for screen tracking.
    ///
    /// - Parameter screen: the ``Screen`` object representing the current screen
    @objc public func setCurrentScreen(screen: Screen) {
        hackleAppCore.setCurrentScreen(screen: screen, hackleAppContext: .default)
    }
}

// MARK: async interaction
extension HackleApp {

    /// Sets or replaces the current user, and suspends until the user synchronization completes.
    ///
    /// The user is updated synchronously before the first suspension point.
    ///
    /// - Parameter user: the ``User`` to set
    public func setUser(user: User) async {
        await hackleAppCore.setUser(user: user, hackleAppContext: .default).value
    }

    /// Sets the userId for the current user, and suspends until the user synchronization completes.
    ///
    /// The user is updated synchronously before the first suspension point.
    ///
    /// - Parameter userId: the userId to set for the user. Can be null to identify an anonymous user
    public func setUserId(userId: String?) async {
        await hackleAppCore.setUserId(userId: userId, hackleAppContext: .default).value
    }

    /// Sets a custom device ID, and suspends until the user synchronization completes.
    ///
    /// The user is updated synchronously before the first suspension point.
    ///
    /// - Parameter deviceId: the custom device ID to set
    public func setDeviceId(deviceId: String) async {
        await hackleAppCore.setDeviceId(deviceId: deviceId, hackleAppContext: .default).value
    }

    /// Sets a single user property.
    ///
    /// - Parameters:
    ///   - key: the key of the property
    ///   - value: the value of the property
    @available(*, deprecated, message: "Use updateUserProperties(operations:) instead.")
    public func setUserProperty(key: String, value: Any?) async {
        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()
        await updateUserProperties(operations: operations)
    }

    /// Updates user properties with a set of operations.
    ///
    /// - Parameter operations: a set of ``PropertyOperations`` to apply to user properties
    public func updateUserProperties(operations: PropertyOperations) async {
        await hackleAppCore.updateUserProperties(operations: operations, hackleAppContext: .default).value
    }

    /// Resets the current user, and suspends until the user synchronization completes.
    ///
    /// The user is updated synchronously before the first suspension point.
    public func resetUser() async {
        await hackleAppCore.resetUser(hackleAppContext: .default).value
    }

    /// Sets the phone number for the current user.
    ///
    /// - Parameter phoneNumber: the phone number to set
    public func setPhoneNumber(phoneNumber: String) async {
        hackleAppCore.setPhoneNumber(phoneNumber: phoneNumber, hackleAppContext: .default)
    }

    /// Removes the phone number from the current user.
    public func unsetPhoneNumber() async {
        hackleAppCore.unsetPhoneNumber(hackleAppContext: .default)
    }

    /// Fetches the latest configuration from the Hackle servers, and suspends until the fetch completes.
    public func fetch() async {
        await hackleAppCore.fetch().value
    }
}

extension HackleApp {
    func initialize(user: User? = nil, completion: @escaping @Sendable () -> ()) {
        hackleAppCore.initialize(user: user, completion: completion)
    }

    static func create(sdkKey: String, config: HackleConfig) -> HackleApp {
        let clock = SystemClock.shared
        let sdk = Sdk.of(sdkKey: sdkKey, config: config)

        let globalKeyValueRepository = UserDefaultsKeyValueRepository(userDefaults: UserDefaults.standard, suiteName: nil)
        let keyValueRepositoryBySdkKey = UserDefaultsKeyValueRepository.of(suiteName: String(format: storageSuiteNameDefault, sdkKey))
        let platformManager = PlatformManager(keyValueRepository: globalKeyValueRepository)
        let applicationInstallDeterminer = ApplicationInstallDeterminer()
        let applicationLifecycleManager = DefaultApplicationLifecycleManager.shared

        let httpClient = DefaultHttpClient(sdk: sdk)

        // - Synchronizer

        let compositeSynchronizer = CompositeSynchronizer()
        let pollingSynchronizer = PollingSynchronizer(
            delegate: compositeSynchronizer,
            scheduler: Schedulers.dispatch(queue: DispatchQueue(label: "io.hackle.scheduler.PollingSynchronizer")),
            interval: config.pollingInterval
        )

        // - WorkspaceManager
        let fileStorage = try? DefaultFileStorage(sdkKey: sdkKey)
        let workspaceMode: WorkspaceMode = {
            switch config.evaluationMode {
            case .local:
                let httpWorkspaceConfigFetcher = DefaultHttpWorkspaceConfigFetcher(
                    config: config,
                    sdk: sdk,
                    httpClient: httpClient
                )
                let workspaceConfigManager = WorkspaceConfigManager(
                    httpWorkspaceConfigFetcher: httpWorkspaceConfigFetcher,
                    repository: DefaultWorkspaceConfigRepository(fileStorage: fileStorage)
                )
                compositeSynchronizer.add(synchronizer: workspaceConfigManager)
                return .local(workspaceConfigManager)
            case .remote:
                let evaluateClient = RemoteEvaluateClient(sdkUrl: config.sdkUrl, httpClient: httpClient)
                let evaluationManager = WorkspaceEvaluationManager(
                    fullEvaluator: FullWorkspaceRemoteEvaluator(client: evaluateClient),
                    partialEvaluator: PartialWorkspaceRemoteEvaluator(client: evaluateClient),
                    repository: FileWorkspaceEvaluationRepository(fileStorage: fileStorage),
                    cache: LruWorkspaceEvaluationCache(capacity: 4)
                )
                return .remote(evaluationManager)
            }
        }()

        // - UserManager
        let userRepository = UserRepository(repository: keyValueRepositoryBySdkKey)
        let userManager: UserManager = switch workspaceMode {
        case .local:
            LocalUserManager(
                device: platformManager.device,
                bundleInfo: platformManager.bundleInfo,
                repository: userRepository,
                cohortFetcher: DefaultUserCohortFetcher(config: config, httpClient: httpClient),
                targetFetcher: DefaultUserTargetEventFetcher(config: config, httpClient: httpClient),
                clock: clock
            )
        case .remote(let evaluationManager):
            RemoteUserManager(
                clock: clock,
                device: platformManager.device,
                bundleInfo: platformManager.bundleInfo,
                repository: userRepository,
                evaluationManager: evaluationManager
            )
        }
        compositeSynchronizer.add(synchronizer: userManager)

        // - SessionManager
        let sessionManager = DefaultSessionManager(
            userManager: userManager,
            keyValueRepository: globalKeyValueRepository,
            applicationLifecycleManager: applicationLifecycleManager,
            sessionPolicy: config.sessionPolicy
        )
        userManager.addListener(listener: sessionManager)

        let sessionUserDecorator = SessionUserDecorator(sessionManager: sessionManager)

        // - ScreenManager
        let screenManager = DefaultScreenManager(
            userManager: userManager,
            screenViewDedupEnabled: config.screenViewDedupEnabled
        )

        // - EngagementManager
        let engagementManager = EngagementManager(
            userManager: userManager,
            screenManager: screenManager,
            minimumEngagementDuration: 1.0
        )
        screenManager.addListener(listener: engagementManager)

        // - EventProcessor
        let workspaceDatabase = WorkspaceDatabase(sdkKey: sdkKey)
        let eventRepository = SQLiteEventRepository(database: workspaceDatabase)
        let coreQueue = DispatchQueue(label: "io.hackle.CoreQueue", qos: .utility)
        let httpQueue = DispatchQueue(label: "io.hackle.HttpQueue", qos: .utility)
        let eventBackoffController = DefaultUserEventBackoffController(userEventRetryInterval: config.eventFlushInterval, clock: SystemClock.shared)

        let eventDispatcher = DefaultUserEventDispatcher(
            eventBaseUrl: config.eventUrl,
            coreQueue: coreQueue,
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
            dedupInterval: config.exposureEventDedupInterval
        )

        let exposureEventDedupDeterminer = ExposureEventDedupDeterminer(
            repository: exposureEventDedupRepository,
            dedupInterval: config.exposureEventDedupInterval
        )

        applicationLifecycleManager.setDispatchQueue(queue: coreQueue)
        applicationLifecycleManager.addListener(listener: rcEventDedupDeterminer)
        applicationLifecycleManager.addListener(listener: exposureEventDedupDeterminer)

        let dedupDeterminer = DelegatingUserEventDedupDeterminer(determiners: [
            rcEventDedupDeterminer,
            exposureEventDedupDeterminer
        ])
        let dedupEventFilter = DedupUserEventFilter(eventDedupDeterminer: dedupDeterminer)
        eventFilters.append(dedupEventFilter)

        // OptOutManager
        let optOutManager = OptOutManager(
            configOptOutTracking: config.optOutTracking
        )

        let sessionUserEventDecorator = SessionUserEventDecorator(userDecorator: sessionUserDecorator)
        eventDecorators.append(sessionUserEventDecorator)

        if config.appMode == .web_view_wrapper {
            eventFilters.append(WebViewWrapperUserEventFilter())
            eventDecorators.append(WebViewWrapperUserEventDecorator())
        }

        let screenUserEventDecorator = ScreenUserEventDecorator(screenManager: screenManager)

        let eventProcessor = DefaultUserEventProcessor(
            eventFilters: eventFilters,
            eventDecorator: eventDecorators,
            eventPublisher: eventPublisher,
            coreQueue: coreQueue,
            eventRepository: eventRepository,
            eventRepositoryMaxSize: HackleConfig.DEFAULT_EVENT_REPOSITORY_MAX_SIZE,
            eventFlushScheduler: Schedulers.dispatch(queue: DispatchQueue(label: "io.hackle.scheduler.DefaultUserEventProcessor.flush")),
            eventFlushInterval: config.eventFlushInterval,
            eventFlushThreshold: config.eventFlushThreshold,
            eventFlushMaxBatchSize: config.eventFlushThreshold * 2 + 1,
            eventDispatcher: eventDispatcher,
            sessionManager: sessionManager,
            userManager: userManager,
            screenUserEventDecorator: screenUserEventDecorator,
            eventBackoffController: eventBackoffController,
            optOutManager: optOutManager
        )
        optOutManager.addListener(listener: eventProcessor)

        // - Core

        let abOverrideStorage = DefaultExperimentManualOverrideStorage.create(suiteName: String(format: storageSuiteNameAB, sdkKey))
        let ffOverrideStorage = DefaultExperimentManualOverrideStorage.create(suiteName: String(format: storageSuiteNameFF, sdkKey))
        let inAppMessageHiddenStorage = DefaultInAppMessageHiddenStorage.create(suiteName: String(format: storageSuiteNameIAM, sdkKey))
        let inAppMessageImpressionStorage = DefaultInAppMessageImpressionStorage.create(suiteName: String(format: storageSuiteNameIAMImpression, sdkKey))
        let coreContext = HackleCoreContext.create()

        let evaluateProcessor = EvaluateProcessor.create(
            context: coreContext,
            clock: clock,
            eventProcessor: eventProcessor,
            overrideStorage: DelegatingManualOverrideStorage(storages: [abOverrideStorage, ffOverrideStorage]),
            impressionStorage: inAppMessageImpressionStorage,
            hiddenStorage: inAppMessageHiddenStorage
        )

        let decisionProcessor: DecisionProcessor = switch workspaceMode {
        case .local(let workspaceConfigManager):
            LocalDecisionProcessor(
                workspaceFetcher: workspaceConfigManager,
                evaluateProcessor: evaluateProcessor
            )
        case .remote(let workspaceEvaluationManager):
            RemoteDecisionProcessor(
                workspaceFetcher: workspaceEvaluationManager,
                evaluateProcessor: evaluateProcessor
            )
        }

        let core = DefaultHackleCore(
            workspaceManager: workspaceMode.manager,
            decisionProcessor: decisionProcessor,
            eventProcessor: eventProcessor,
            clock: clock
        )

        // - PropertiesEventTracker

        let propertiesEventTracker = PropertiesEventTracker(
            core: core,
            eventProcessor: eventProcessor,
            userManager: userManager
        )
        userManager.addListener(listener: propertiesEventTracker)

        // - ApplicationLifecycleListener
        // addListener는 등록 순서대로 append만 하고, onForeground/onBackground도 그 순서대로 순회한다(정렬 없음).
        // 즉 아래 등록 위치가 곧 호출 순서 계약이다 — 이벤트 생산자(applicationEventTracker, engagementManager 등)는
        // eventProcessor보다 반드시 먼저 등록되어야 한다. 리스너 추가 시 의도한 위치에 신중히 삽입할 것.

        applicationLifecycleManager.addListener(listener: pollingSynchronizer)
        applicationLifecycleManager.addListener(listener: sessionManager)
        applicationLifecycleManager.addListener(listener: userManager)

        // - ApplicationInstallStateManager

        let applicationInstallStateManager = ApplicationInstallStateManager(
            platformManager: platformManager,
            applicationInstallDeterminer:
            applicationInstallDeterminer,
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

        if config.automaticAppLifecycleTracking {
            applicationLifecycleManager.addListener(listener: applicationEventTracker)
        }
        applicationInstallStateManager.addListener(listener: applicationEventTracker)

        // - InAppMessage

        let urlHandler = ApplicationUrlHandler()
        let inAppMessageActionHandlerFactory = DefaultInAppMessageActionHandlerFactory(handlers: [
            InAppMessageCloseActionHandler(),
            InAppMessageLinkActionHandler(urlHandler: urlHandler),
            InAppMessageLinkAndCloseHandler(urlHandler: urlHandler),
            InAppMessageHiddenActionHandler(clock: clock, storage: inAppMessageHiddenStorage)
        ])
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
        let inAppMessageHtmlContentResolverFactory = DefaultInAppMessageHtmlContentResolverFactory(resolvers: [
            PathInAppMessageHtmlContentResolver(httpClient: httpClient),
            TextInAppMessageHtmlContentResolver()
        ])
        let inAppMessageUI = HackleInAppMessageUI(
            clock: clock,
            eventProcessor: inAppMessageViewEventProcessor,
            htmlContentResolverFactory: inAppMessageHtmlContentResolverFactory
        )

        let inAppMessageRecorder = DefaultInAppMessageRecorder(
            storage: inAppMessageImpressionStorage
        )
        let inAppMessagePresentProcessor = DefaultInAppMessagePresentProcessor(
            coreQueue: coreQueue,
            presenter: inAppMessageUI,
            recorder: inAppMessageRecorder
        )

        let inAppMessageIdentifierChecker = DefaultInAppMessageIdentifierChecker()
        let inAppMessageDeliverEvaluator: InAppMessageDeliverEvaluator = switch workspaceMode {
        case .local(let workspaceConfigManager):
            InAppMessageDeliverLocalEvaluator(
                workspaceFetcher: workspaceConfigManager,
                evaluateProcessor: evaluateProcessor
            )
        case .remote(let workspaceEvaluationManager):
            InAppMessageDeliverRemoteEvaluator(
                workspaceManager: workspaceEvaluationManager,
                evaluateProcessor: evaluateProcessor
            )
        }
        let inAppMessageDeliverProcessor = DefaultInAppMessageDeliverProcessor(
            userManager: userManager,
            userDecorator: sessionUserDecorator,
            identifierChecker: inAppMessageIdentifierChecker,
            evaluator: inAppMessageDeliverEvaluator,
            presentProcessor: inAppMessagePresentProcessor,
            lifecycleManager: applicationLifecycleManager
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
            DelayedInAppMessageScheduler(deliverProcessor: inAppMessageDeliverProcessor, delayManager: inAppMessageDelayManager)
        ])
        let inAppMessageScheduleProcessor = DefaultInAppMessageScheduleProcessor(
            actionDeterminer: DefaultInAppMessageScheduleActionDeterminer(),
            schedulerFactory: inAppMessageSchedulerFactory
        )
        inAppMessageDelayScheduler.setListener(listener: inAppMessageScheduleProcessor)

        let inAppMessageTriggerEventMatcher = DefaultInAppMessageTriggerEventMatcher(
            targetMatcher: coreContext.get(TargetMatcher.self)!
        )
        let inAppMessageTriggerDeterminer: InAppMessageTriggerDeterminer = switch workspaceMode {
        case .local(let workspaceConfigManager):
            LocalInAppMessageTriggerDeterminer(
                eventMatcher: inAppMessageTriggerEventMatcher,
                workspaceFetcher: workspaceConfigManager,
                evaluateProcessor: evaluateProcessor
            )
        case .remote(let workspaceEvaluationManager):
            RemoteInAppMessageTriggerDeterminer(
                eventMatcher: inAppMessageTriggerEventMatcher,
                workspaceManager: workspaceEvaluationManager,
                evaluateProcessor: evaluateProcessor
            )
        }
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

        let sharedDatabase = SharedDatabase.shared
        let notificationManager = DefaultNotificationManager(
            core: core,
            coreQueue: coreQueue,
            workspaceManager: workspaceMode.manager,
            userManager: userManager,
            repository: DefaultNotificationRepository(
                sharedDatabase: sharedDatabase
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
        if config.monitoringEnabled {
            HackleApp.metricConfiguration(
                config: config,
                applicationLifecycleManager: applicationLifecycleManager,
                coreQueue: coreQueue,
                httpQueue: httpQueue,
                httpClient: httpClient
            )
        }

        // - ViewLifecycle

        let viewLifecycleManager = ViewLifecycleManager.shared
        if config.automaticScreenTracking {
            viewLifecycleManager.addListener(listener: screenManager)
            applicationLifecycleManager.addListener(listener: screenManager)
        }
        viewLifecycleManager.addListener(listener: engagementManager)
        viewLifecycleManager.setDispatchQueue(queue: coreQueue)

        applicationLifecycleManager.addListener(listener: engagementManager)

        // 백그라운드 전환 시 flush가 이벤트 생산자보다 뒤에 실행되도록 마지막에 등록한다.
        applicationLifecycleManager.addListener(listener: eventProcessor)

        let throttleLimiter = ScopingThrottleLimiter(interval: 60, limit: 1, clock: SystemClock.shared)
        let throttler = DefaultThrottler(limiter: throttleLimiter)

        let hackleAppCore = DefaultHackleAppCore(
            core: core,
            evaluationMode: config.evaluationMode,
            coreQueue: coreQueue,
            synchronizer: pollingSynchronizer,
            applicationLifecycleObserver: ApplicationLifecycleObserver.shared,
            viewLifecycleObserver: ViewLifecycleObserver.shared,
            userManager: userManager,
            workspaceManager: workspaceMode.manager,
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
            optOutManager: optOutManager
        )

        let invocationHandlerFactory = DefaultInvocationHandlerFactory(core: hackleAppCore)
        let invocationProcessor = DefaultInvocationProcessor(handlerFactory: invocationHandlerFactory)
        let hackleInvocator = DefaultHackleInvocator(processor: invocationProcessor)

        return HackleApp(
            hackleAppCore: hackleAppCore,
            sdk: sdk,
            config: config,
            hackleInvocator: hackleInvocator
        )
    }

    private static func inAppMessageDisabled(config: HackleConfig) -> Bool {
        if let disableInAppMessage = config.extra["$disable_inappmessage"],
           disableInAppMessage == "true"
        {
            return true
        }

        return false
    }

    private static func metricConfiguration(
        config: HackleConfig,
        applicationLifecycleManager: ApplicationLifecycleManager,
        coreQueue: DispatchQueue,
        httpQueue: DispatchQueue,
        httpClient: HttpClient
    ) {
        let monitoringMetricRegistry = MonitoringMetricRegistry(
            monitoringBaseUrl: config.monitoringUrl,
            coreQueue: coreQueue,
            httpQueue: httpQueue,
            httpClient: httpClient
        )

        applicationLifecycleManager.addListener(listener: monitoringMetricRegistry)
        Metrics.addRegistry(registry: monitoringMetricRegistry)
    }
}

fileprivate enum WorkspaceMode {
    case local(WorkspaceConfigManager)
    case remote(WorkspaceEvaluationManager)
    
    var manager: WorkspaceManager {
            switch self {
            case .local(let manager):
                return manager
            case .remote(let manager):
                return manager
            }
        }
}
