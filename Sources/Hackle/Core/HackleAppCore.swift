//
//  HackleAppCore.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

import Foundation

protocol HackleAppCore: AnyObject {
    var deviceId: String { get }
    var sessionId: String { get }
    var user: User { get }
    @MainActor var currentInAppMessageView: InAppMessageView? { get }

    func initialize(user: User?, completion: @escaping @Sendable () -> ())

    @MainActor func getInAppMessageView(viewId: String) -> InAppMessageView?

    func showUserExplorer()

    func hideUserExplorer()

    @discardableResult
    func setUser(user: User, hackleAppContext: HackleAppContext) -> Task<Void, Never>

    @discardableResult
    func setUserId(userId: String?, hackleAppContext: HackleAppContext) -> Task<Void, Never>

    @discardableResult
    func setDeviceId(deviceId: String, hackleAppContext: HackleAppContext) -> Task<Void, Never>

    @discardableResult
    func updateUserProperties(operations: PropertyOperations, hackleAppContext: HackleAppContext) -> Task<Void, Never>

    func updatePushSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext)

    func updateSmsSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext)

    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext)

    @discardableResult
    func resetUser(hackleAppContext: HackleAppContext) -> Task<Void, Never>

    func setPhoneNumber(phoneNumber: String, hackleAppContext: HackleAppContext)

    func unsetPhoneNumber(hackleAppContext: HackleAppContext)

    func variationDetail(experimentKey: Int, hackleAppContext: HackleAppContext) -> Decision

    func allVariationDetails(hackleAppContext: HackleAppContext) -> [Int: Decision]

    func featureFlagDetail(featureKey: Int, hackleAppContext: HackleAppContext) -> FeatureFlagDecision

    func track(event: Event, hackleAppContext: HackleAppContext)

    func remoteConfig(key: String, defaultValue: HackleValue, hackleAppContext: HackleAppContext) -> RemoteConfigDecision

    func setCurrentScreen(screen: Screen, hackleAppContext: HackleAppContext)

    var isOptOutTracking: Bool { get }
    func setOptOutTracking(optOut: Bool)

    @discardableResult
    func fetch() -> Task<Void, Never>

    func setPushToken(deviceToken: Data)

    func setInAppMessageDelegate(_ delegate: HackleInAppMessageDelegate?)
}

class DefaultHackleAppCore: HackleAppCore, @unchecked Sendable {
    private let core: HackleCore
    private let evaluationMode: EvaluationMode
    private let coreQueue: DispatchQueue
    private let synchronizer: Synchronizer
    private let applicationLifecycleObserver: ApplicationLifecycleObserver
    private let viewLifecycleObserver: ViewLifecycleObserver
    private let userManager: UserManager
    private let workspaceManager: WorkspaceManager
    private let sessionManager: SessionManager
    private let screenManager: ScreenManager
    private let eventProcessor: UserEventProcessor
    private let pushTokenRegistry: PushTokenRegistry
    private let notificationManager: NotificationManager
    private let fetchThrottler: Throttler
    private let platformManager: PlatformManager
    private let inAppMessageUI: HackleInAppMessageUI
    private let applicationInstallStateManager: ApplicationInstallStateManager
    private let userExplorer: HackleUserExplorer
    private let optOutManager: OptOutManager
    private let onInitializedRef = AtomicReference<(@Sendable () -> ())?>(value: nil)

    @MainActor private var userExplorerView: HackleUserExplorerView? = nil

    var deviceId: String {
        platformManager.device.id
    }

    var sessionId: String {
        sessionManager.requiredSession.id
    }

    var user: User {
        userManager.currentUser
    }

    var isOptOutTracking: Bool {
        optOutManager.isOptOutTracking
    }

    var currentInAppMessageView: InAppMessageView? {
        return inAppMessageUI.currentView
    }

    init(
        core: HackleCore,
        evaluationMode: EvaluationMode,
        coreQueue: DispatchQueue,
        synchronizer: Synchronizer,
        applicationLifecycleObserver: ApplicationLifecycleObserver,
        viewLifecycleObserver: ViewLifecycleObserver,
        userManager: UserManager,
        workspaceManager: WorkspaceManager,
        sessionManager: SessionManager,
        screenManager: ScreenManager,
        eventProcessor: UserEventProcessor,
        pushTokenRegistry: PushTokenRegistry,
        notificationManager: NotificationManager,
        fetchThrottler: Throttler,
        platformManager: PlatformManager,
        inAppMessageUI: HackleInAppMessageUI,
        applicationInstallStateManager: ApplicationInstallStateManager,
        userExplorer: HackleUserExplorer,
        optOutManager: OptOutManager
    ) {
        self.core = core
        self.evaluationMode = evaluationMode
        self.coreQueue = coreQueue
        self.synchronizer = synchronizer
        self.applicationLifecycleObserver = applicationLifecycleObserver
        self.viewLifecycleObserver = viewLifecycleObserver
        self.userManager = userManager
        self.workspaceManager = workspaceManager
        self.sessionManager = sessionManager
        self.screenManager = screenManager
        self.eventProcessor = eventProcessor
        self.pushTokenRegistry = pushTokenRegistry
        self.notificationManager = notificationManager
        self.fetchThrottler = fetchThrottler
        self.platformManager = platformManager
        self.inAppMessageUI = inAppMessageUI
        self.applicationInstallStateManager = applicationInstallStateManager
        self.userExplorer = userExplorer
        self.optOutManager = optOutManager
    }

    func initialize(user: User?, completion: @escaping @Sendable () -> ()) {
        userManager.initialize(user: user)
        sessionManager.initialize()
        onInitializedRef.set(newValue: completion)
        Task {
            await self.platformManager.initialize()
            self.applicationLifecycleObserver.initialize()
            self.viewLifecycleObserver.initialize()
            await DefaultApplicationLifecycleManager.shared.publishWillEnterForegroundIfNeeded()
            self.coreQueue.async { [weak self] in
                guard let self = self else { return }
                if let completion = self.onInitializedRef.getAndSet(newValue: nil) {
                    self.initialize(completion: completion)
                }
            }
        }
    }

    private func initialize(completion: @escaping @Sendable () -> ()) {
        workspaceManager.initialize()
        eventProcessor.initialize()
        applicationInstallStateManager.initialize()
        // 초기화 중 들어온 coreQueue 작업(이벤트 처리 등)이 sync 완료 후 처리되도록 큐를 잡아둔다.
        // suspend는 새 작업의 시작만 막으므로 스레드를 블로킹하지 않는다.
        coreQueue.suspend()
        Task { [weak self, coreQueue = self.coreQueue] in
            guard let self = self else {
                coreQueue.resume()
                completion()
                return
            }
            await self.synchronizer.safeSync()
            self.pushTokenRegistry.flush()
            self.notificationManager.flush()
            self.applicationInstallStateManager.checkApplicationInstall()
            coreQueue.resume()
            completion()
        }
    }

    func getInAppMessageView(viewId: String) -> InAppMessageView? {
        return inAppMessageUI.getView(viewId: viewId)
    }

    func showUserExplorer() {
        if evaluationMode == .remote {
            Log.info("UserExplorer is not supported in EvaluationMode.REMOTE")
            return
        }
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000)
            guard let self else { return }
            if self.userExplorerView == nil {
                self.userExplorerView = HackleUserExplorerView(
                    hackleUserExplorer: self.userExplorer
                )
            }
            self.userExplorerView?.attach()
        }
        Metrics.counter(name: "user.explorer.show").increment()
    }

    func hideUserExplorer() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self?.userExplorerView?.detach()
        }
    }

    // mutation은 userManager 내부에서 동기적으로 끝난다(동기 프리픽스). 여기서 Task { await ... }로 감싸면
    // mutation까지 지연되므로, 반환된 Task(네트워크 sync)를 그대로 forward한다.
    @discardableResult
    func setUser(user: User, hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        return userManager.setUser(user: user)
    }

    @discardableResult
    func setUserId(userId: String?, hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        return userManager.setUserId(userId: userId)
    }

    @discardableResult
    func setDeviceId(deviceId: String, hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        return userManager.setDeviceId(deviceId: deviceId)
    }

    @discardableResult
    func updateUserProperties(operations: PropertyOperations, hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        return userManager.updateProperties(operations: operations)
    }

    func updatePushSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        track(event: operations.toEvent(key: "$push_subscriptions"), hackleAppContext: hackleAppContext)
        eventProcessor.flush()
    }

    func updateSmsSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        track(event: operations.toEvent(key: "$sms_subscriptions"), hackleAppContext: hackleAppContext)
        eventProcessor.flush()
    }

    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        track(event: operations.toEvent(key: "$kakao_subscriptions"), hackleAppContext: hackleAppContext)
        eventProcessor.flush()
    }

    @discardableResult
    func resetUser(hackleAppContext: HackleAppContext) -> Task<Void, Never> {
        return userManager.resetUser()
    }

    func setPhoneNumber(phoneNumber: String, hackleAppContext: HackleAppContext) {
        let event = PropertyOperationsBuilder()
            .set(PIIProperty.phoneNumber.rawValue, phoneNumber)
            .build()
            .toSecuredEvent()
        track(event: event, hackleAppContext: hackleAppContext)
        eventProcessor.flush()
    }

    func unsetPhoneNumber(hackleAppContext: HackleAppContext) {
        let event = PropertyOperationsBuilder()
            .unset(PIIProperty.phoneNumber.rawValue)
            .build()
            .toSecuredEvent()
        track(event: event, hackleAppContext: hackleAppContext)
        eventProcessor.flush()
    }

    func variationDetail(experimentKey: Int, hackleAppContext: HackleAppContext) -> Decision {
        let sample = TimerSample.start()
        let decision: Decision
        do {
            let hackleUser = userManager.hackleUser(appContext: hackleAppContext)
            decision = try core.experiment(
                experimentKey: Int64(experimentKey),
                user: hackleUser
            )
        } catch {
            Log.error("Unexpected error while deciding variation for experiment[\(experimentKey)]: \(String(describing: error))")
            decision = Decision.of(experiment: nil, variation: VariationKeys.control, reason: DecisionReason.EXCEPTION)
        }
        DecisionMetrics.experiment(sample: sample, key: experimentKey, decision: decision)
        return decision
    }

    func allVariationDetails(hackleAppContext: HackleAppContext) -> [Int: Decision] {
        do {
            let hackleUser = userManager.hackleUser(appContext: hackleAppContext)
            return try core.experiments(user: hackleUser).associate { experiment, decision in
                (Int(experiment.key), decision)
            }
        } catch {
            Log.error("Unexpected error while deciding variations for experiments: \(String(describing: error))")
            return [:]
        }
    }

    func featureFlagDetail(featureKey: Int, hackleAppContext: HackleAppContext) -> FeatureFlagDecision {
        let sample = TimerSample.start()
        let decision: FeatureFlagDecision
        do {
            let hackleUser = userManager.hackleUser(appContext: hackleAppContext)
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

    func track(event: Event, hackleAppContext: HackleAppContext) {
        let hackleUser = userManager.hackleUser(appContext: hackleAppContext)
        core.track(event: event, user: hackleUser)
    }

    func remoteConfig(key: String, defaultValue: HackleValue, hackleAppContext: HackleAppContext) -> RemoteConfigDecision {
        let sample = TimerSample.start()
        let decision: RemoteConfigDecision
        do {
            let hackleUser = userManager.hackleUser(appContext: hackleAppContext)
            decision = try core.remoteConfig(parameterKey: key, user: hackleUser, defaultValue: defaultValue)
        } catch {
            Log.error("Unexpected exception while deciding remote config parameter[\(key)]. Returning default value: \(String(describing: error))")
            decision = RemoteConfigDecision(value: defaultValue, reason: DecisionReason.EXCEPTION)
        }
        DecisionMetrics.remoteConfig(sample: sample, key: key, decision: decision)
        return decision
    }

    func setCurrentScreen(screen: Screen, hackleAppContext: HackleAppContext) {
        screenManager.setCurrentScreen(screen: screen, timestamp: SystemClock.shared.now())
    }

    func setOptOutTracking(optOut: Bool) {
        optOutManager.setOptOutTracking(optOut: optOut)
    }

    @discardableResult
    func fetch() -> Task<Void, Never> {
        // Throttler.execute는 반환 전에 accept/reject 중 하나를 동기적으로 호출하는 계약이다.
        // 계약 위반(둘 다 미호출)은 디버그에서 즉시 드러내되, 릴리스에서는 크래시 대신 무해한 no-op Task를 반환한다.
        var task: Task<Void, Never>? = nil
        fetchThrottler.execute(
            accept: {
                task = Task { await self.synchronizer.safeSync() }
            },
            reject: {
                Log.debug("Too many quick fetch requests")
                task = Task {}
            }
        )
        if task == nil {
            assertionFailure("Throttler.execute must synchronously call accept or reject before returning")
        }
        return task ?? Task {}
    }

    func setPushToken(deviceToken: Data) {
        pushTokenRegistry.register(token: PushToken.of(value: deviceToken), timestamp: Date())
    }

    func setInAppMessageDelegate(_ delegate: HackleInAppMessageDelegate?) {
        inAppMessageUI.delegate = delegate
    }
}
