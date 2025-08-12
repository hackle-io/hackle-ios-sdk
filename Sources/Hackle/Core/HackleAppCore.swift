//
//  HackleAppCore.swift
//  Hackle
//
//  Created by sungwoo.yeo on 8/12/25.
//

import Foundation

class HackleAppCore: HackleAppCoreProtocol {
    private let core: HackleCore
    private let eventQueue: DispatchQueue
    private let synchronizer: Synchronizer
    private let userManager: UserManager
    private let workspaceManager: WorkspaceManager
    private let sessionManager: SessionManager
    private let screenManager: ScreenManager
    private let eventProcessor: UserEventProcessor
    private let lifecycleManager: LifecycleManager
    private let pushTokenRegistry: PushTokenRegistry
    private let notificationManager: NotificationManager
    private let piiEventManager: PIIEventManager
    private let fetchThrottler: Throttler
    private let device: Device
    private let inAppMessageUI: HackleInAppMessageUI
    
    let userExplorer: HackleUserExplorer
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
        lifecycleManager: LifecycleManager,
        pushTokenRegistry: PushTokenRegistry,
        notificationManager: NotificationManager,
        piiEventManager: PIIEventManager,
        fetchThrottler: Throttler,
        device: Device,
        inAppMessageUI: HackleInAppMessageUI,
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
        self.lifecycleManager = lifecycleManager
        self.pushTokenRegistry = pushTokenRegistry
        self.notificationManager = notificationManager
        self.piiEventManager = piiEventManager
        self.fetchThrottler = fetchThrottler
        self.device = device
        self.inAppMessageUI = inAppMessageUI
        self.userExplorer = userExplorer
    }
    
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
    
    func showUserExplorer() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.1) {
            if self.userExplorerView == nil {
                self.userExplorerView = HackleUserExplorerView()
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

    func setUser(user: User, completion: @escaping () -> ()) {
        let updated = userManager.setUser(user: user)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    func setUserId(userId: String?, completion: @escaping () -> ()) {
        let updated = userManager.setUserId(userId: userId)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    func setDeviceId(deviceId: String, completion: @escaping () -> ()) {
        let updated = userManager.setDeviceId(deviceId: deviceId)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    func updateUserProperties(operations: PropertyOperations, completion: @escaping () -> ()) {
        track(event: operations.toEvent(), user: nil)
        eventProcessor.flush()
        userManager.updateProperties(operations: operations)
        completion()
    }
    
    func updatePushSubscriptions(operations: HackleSubscriptionOperations) {
        track(event: operations.toEvent(key: "$push_subscriptions"), user: nil)
        eventProcessor.flush()
    }
    
    func updateSmsSubscriptions(operations: HackleSubscriptionOperations) {
        track(event: operations.toEvent(key: "$sms_subscriptions"), user: nil)
        eventProcessor.flush()
    }

    
    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations) {
        track(event: operations.toEvent(key: "$kakao_subscriptions"), user: nil)
        eventProcessor.flush()
    }

    func resetUser(completion: @escaping () -> ()) {
        let updated = userManager.resetUser()
        track(event: PropertyOperations.clearAll().toEvent(), user: nil)
        userManager.syncIfNeeded(updated: updated, completion: completion)
    }

    func setPhoneNumber(phoneNumber: String, completion: @escaping () -> ()) {
        let event = piiEventManager.setPhoneNumber(phoneNumber: PhoneNumber.create(phoneNumber: phoneNumber))
        track(event: event, user: nil)
        eventProcessor.flush()
        completion()
    }
    
    func unsetPhoneNumber(completion: @escaping () -> ()) {
        let event = piiEventManager.unsetPhoneNumber()
        track(event: event, user: nil)
        eventProcessor.flush()
        completion()
    }

    func variationDetail(experimentKey: Int, user: User?, defaultVariation: String) -> Decision {
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

    func allVariationDetails(user: User?) -> [Int: Decision] {
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

    func featureFlagDetail(featureKey: Int, user: User?) -> FeatureFlagDecision {
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

    func track(event: Event, user: User?) {
        let hackleUser = userManager.resolve(user: user)
        core.track(event: event, user: hackleUser)
    }

    func remoteConfig(user: User?) -> HackleRemoteConfig {
        DefaultRemoteConfig(user: user, app: core, userManager: userManager)
    }
    
    func setCurrentScreen(screen: Screen) {
        screenManager.setCurrentScreen(screen: screen, timestamp: SystemClock.shared.now())
    }

    func setPushToken(deviceToken: Data) {
        pushTokenRegistry.register(token: PushToken.of(value: deviceToken), timestamp: Date())
    }
    
    func setInAppMessageDelegate(_ delegate: HackleInAppMessageDelegate?) {
        inAppMessageUI.delegate = delegate
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
}

protocol HackleAppCoreProtocol: AnyObject {
    var deviceId: String { get }
    var sessionId: String { get }
    var user: User { get }

    func initialize(user: User?, completion: @escaping () -> ())

    func showUserExplorer()
    
    func hideUserExplorer()
    
    func setUser(user: User, completion: @escaping () -> ())

    func setUserId(userId: String?, completion: @escaping () -> ())

    func setDeviceId(deviceId: String, completion: @escaping () -> ())

    func updateUserProperties(operations: PropertyOperations, completion: @escaping () -> ())
    
    func updatePushSubscriptions(operations: HackleSubscriptionOperations)
    
    func updateSmsSubscriptions(operations: HackleSubscriptionOperations)
    
    func updateKakaoSubscriptions(operations: HackleSubscriptionOperations)

    func resetUser(completion: @escaping () -> ())

    func setPhoneNumber(phoneNumber: String, completion: @escaping () -> ())
    
    func unsetPhoneNumber(completion: @escaping () -> ())

    func variationDetail(experimentKey: Int, user: User?, defaultVariation: String) -> Decision

    func allVariationDetails(user: User?) -> [Int: Decision]

    func featureFlagDetail(featureKey: Int, user: User?) -> FeatureFlagDecision

    func track(event: Event, user: User?)

    func remoteConfig(user: User?) -> HackleRemoteConfig
    
    func setCurrentScreen(screen: Screen)

    func fetch(completion: @escaping () -> ())
}
