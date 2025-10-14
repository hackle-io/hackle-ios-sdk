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

    func initialize(user: User?, completion: @escaping () -> ())

    func showUserExplorer()
    
    func hideUserExplorer()
    
    func setUser(user: User, hackleAppContext: HackleAppContext, completion: @escaping () -> ())

    func setUserId(userId: String?, hackleAppContext: HackleAppContext, completion: @escaping () -> ())

    func setDeviceId(deviceId: String, hackleAppContext: HackleAppContext, completion: @escaping () -> ())

    func updateUserProperties(operations: PropertyOperations, hackleAppContext: HackleAppContext, completion: @escaping () -> ())
    
    func updatePushSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext)
    
    func updateSmsSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext)
    
    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext)

    func resetUser(hackleAppContext: HackleAppContext, completion: @escaping () -> ())

    func setPhoneNumber(phoneNumber: String, hackleAppContext: HackleAppContext, completion: @escaping () -> ())
    
    func unsetPhoneNumber(hackleAppContext: HackleAppContext, completion: @escaping () -> ())

    func variationDetail(experimentKey: Int, user: User?, defaultVariation: String, hackleAppContext: HackleAppContext) -> Decision

    func allVariationDetails(user: User?, hackleAppContext: HackleAppContext) -> [Int: Decision]

    func featureFlagDetail(featureKey: Int, user: User?, hackleAppContext: HackleAppContext) -> FeatureFlagDecision

    func track(event: Event, user: User?, hackleAppContext: HackleAppContext)

    func remoteConfig(key: String, defaultValue: HackleValue, user: User?, hackleAppContext: HackleAppContext) -> RemoteConfigDecision
    
    func setCurrentScreen(screen: Screen, hackleAppContext: HackleAppContext)

    func fetch(completion: @escaping () -> ())
    
    func setPushToken(deviceToken: Data)
    
    func setInAppMessageDelegate(_ delegate: HackleInAppMessageDelegate?)
}


class DefaultHackleAppCore: HackleAppCore {
    private let core: HackleCore
    private let eventQueue: DispatchQueue
    private let synchronizer: Synchronizer
    private let userManager: UserManager
    private let workspaceManager: WorkspaceManager
    private let sessionManager: SessionManager
    private let screenManager: ScreenManager
    private let eventProcessor: UserEventProcessor
    private let pushTokenRegistry: PushTokenRegistry
    private let notificationManager: NotificationManager
    private let fetchThrottler: Throttler
    private let device: Device
    private let inAppMessageUI: HackleInAppMessageUI
    private let applicationInstallStateManager: ApplicationInstallStateManager
    private let userExplorer: HackleUserExplorer
    
    private var userExplorerView: HackleUserExplorerView? = nil
    
    var deviceId: String {
        get {
            device.id
        }
    }
    
    var sessionId: String {
        get {
            sessionManager.requiredSession.id
        }
    }
    
    var user: User {
        get {
            userManager.currentUser
        }
    }
    
    init(
        core: HackleCore,
        eventQueue: DispatchQueue,
        synchronizer: Synchronizer,
        userManager: UserManager,
        workspaceManager: WorkspaceManager,
        sessionManager: SessionManager,
        screenManager: ScreenManager,
        eventProcessor: UserEventProcessor,
        pushTokenRegistry: PushTokenRegistry,
        notificationManager: NotificationManager,
        fetchThrottler: Throttler,
        device: Device,
        inAppMessageUI: HackleInAppMessageUI,
        applicationInstallStateManager: ApplicationInstallStateManager,
        userExplorer: HackleUserExplorer
    ) {
        self.core = core
        self.eventQueue = eventQueue
        self.synchronizer = synchronizer
        self.userManager = userManager
        self.workspaceManager = workspaceManager
        self.sessionManager = sessionManager
        self.screenManager = screenManager
        self.eventProcessor = eventProcessor
        self.pushTokenRegistry = pushTokenRegistry
        self.notificationManager = notificationManager
        self.fetchThrottler = fetchThrottler
        self.device = device
        self.inAppMessageUI = inAppMessageUI
        self.applicationInstallStateManager = applicationInstallStateManager
        self.userExplorer = userExplorer
    }
    
    func initialize(user: User?, completion: @escaping () -> ()) {
        ApplicationLifecycleObserver.shared.initialize()
        ViewLifecycleManager.shared.initialize()
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
        applicationInstallStateManager.initialize()
        synchronizer.sync(completion: { [weak self] in
            guard let self = self else {
                completion()
                return
            }
            self.pushTokenRegistry.flush()
            self.notificationManager.flush()
            self.applicationInstallStateManager.checkApplicationInstall()
            completion()
        })
    }
    
    func showUserExplorer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            if self.userExplorerView == nil {
                self.userExplorerView = HackleUserExplorerView(hackleUserExplorer: self.userExplorer)
            }
            self.userExplorerView?.attach()
        }
        Metrics.counter(name: "user.explorer.show").increment()
    }

    func hideUserExplorer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            self.userExplorerView?.detach()
        }
    }

    func setUser(user: User, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        let updated = userManager.setUser(user: user)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    func setUserId(userId: String?, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        let updated = userManager.setUserId(userId: userId)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    func setDeviceId(deviceId: String, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        let updated = userManager.setDeviceId(deviceId: deviceId)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    func updateUserProperties(operations: PropertyOperations, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        track(event: operations.toEvent(), user: nil, hackleAppContext: hackleAppContext)
        eventProcessor.flush()
        userManager.updateProperties(operations: operations)
        completion()
    }
    
    func updatePushSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        track(event: operations.toEvent(key: "$push_subscriptions"), user: nil, hackleAppContext: hackleAppContext)
        eventProcessor.flush()
    }
    
    func updateSmsSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        track(event: operations.toEvent(key: "$sms_subscriptions"), user: nil, hackleAppContext: hackleAppContext)
        eventProcessor.flush()
    }

    
    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations, hackleAppContext: HackleAppContext) {
        track(event: operations.toEvent(key: "$kakao_subscriptions"), user: nil, hackleAppContext: hackleAppContext)
        eventProcessor.flush()
    }

    func resetUser(hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        let updated = userManager.resetUser()
        track(event: PropertyOperations.clearAll().toEvent(), user: nil, hackleAppContext: hackleAppContext)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    func setPhoneNumber(phoneNumber: String, hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        let event = PropertyOperationsBuilder()
            .set(PIIProperty.phoneNumber.rawValue, phoneNumber)
            .build()
            .toSecuredEvent()
        track(event: event, user: nil, hackleAppContext: hackleAppContext)
        eventProcessor.flush()
        completion()
    }
    
    func unsetPhoneNumber(hackleAppContext: HackleAppContext, completion: @escaping () -> ()) {
        let event = PropertyOperationsBuilder()
            .unset(PIIProperty.phoneNumber.rawValue)
            .build()
            .toSecuredEvent()
        track(event: event, user: nil, hackleAppContext: hackleAppContext)
        eventProcessor.flush()
        completion()
    }

    func variationDetail(experimentKey: Int, user: User?, defaultVariation: String, hackleAppContext: HackleAppContext) -> Decision {
        let sample = TimerSample.start()
        let decision: Decision
        do {
            let hackleUser = userManager.resolve(user: user, hackleAppContext: hackleAppContext)
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

    func allVariationDetails(user: User?, hackleAppContext: HackleAppContext) -> [Int: Decision] {
        do {
            let hackleUser = userManager.resolve(user: user, hackleAppContext: hackleAppContext)
            return try core.experiments(user: hackleUser).associate { experiment, decision in
                (Int(experiment.key), decision)
            }
        } catch let error {
            Log.error("Unexpected error while deciding variations for experiments: \(String(describing: error))")
            return [:]
        }
    }

    func featureFlagDetail(featureKey: Int, user: User?, hackleAppContext: HackleAppContext) -> FeatureFlagDecision {
        let sample = TimerSample.start()
        let decision: FeatureFlagDecision
        do {
            let hackleUser = userManager.resolve(user: user, hackleAppContext: hackleAppContext)
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

    func track(event: Event, user: User?, hackleAppContext: HackleAppContext) {
        let hackleUser = userManager.resolve(user: user, hackleAppContext: hackleAppContext)
        core.track(event: event, user: hackleUser)
    }
    
    func remoteConfig(key: String, defaultValue: HackleValue, user: User?, hackleAppContext: HackleAppContext) -> RemoteConfigDecision {
        let sample = TimerSample.start()
        let decision: RemoteConfigDecision
        do {
            let hackleUser = userManager.resolve(user: user, hackleAppContext: hackleAppContext)
            decision = try core.remoteConfig(parameterKey: key, user: hackleUser, defaultValue: defaultValue)
        } catch let error {
            Log.error("Unexpected exception while deciding remote config parameter[\(key)]. Returning default value: \(String(describing: error))")
            decision = RemoteConfigDecision(value: defaultValue, reason: DecisionReason.EXCEPTION)
        }
        DecisionMetrics.remoteConfig(sample: sample, key: key, decision: decision)
        return decision
    }
    
    func setCurrentScreen(screen: Screen, hackleAppContext: HackleAppContext) {
        screenManager.setCurrentScreen(screen: screen, timestamp: SystemClock.shared.now())
    }

    func fetch(completion: @escaping () -> ()) {
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
    
    func setPushToken(deviceToken: Data) {
        pushTokenRegistry.register(token: PushToken.of(value: deviceToken), timestamp: Date())
    }
    
    func setInAppMessageDelegate(_ delegate: HackleInAppMessageDelegate?) {
        inAppMessageUI.delegate = delegate
    }
}

