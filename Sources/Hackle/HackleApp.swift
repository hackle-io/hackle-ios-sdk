//
// Created by yong on 2020/12/11.
//

import Foundation

/// Entry point of Hackle Sdk.
@objc public final class HackleApp: NSObject {

    private let internalApp: HackleInternalApp
    private let userResolver: HackleUserResolver
    private let device: Device

    @objc public var deviceId: String {
        get {
            device.id
        }
    }

    init(internalApp: HackleInternalApp, userResolver: HackleUserResolver, device: Device) {
        self.internalApp = internalApp
        self.userResolver = userResolver
        self.device = device
    }

    @objc public func variation(experimentKey: Int, defaultVariation: String = "A") -> String {
        variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation).variation
    }

    @objc public func variation(experimentKey: Int, userId: String, defaultVariation: String = "A") -> String {
        variationDetail(experimentKey: experimentKey, userId: userId, defaultVariation: defaultVariation).variation
    }

    @objc public func variation(experimentKey: Int, user: User, defaultVariation: String = "A") -> String {
        variationDetail(experimentKey: experimentKey, user: user, defaultVariation: defaultVariation).variation
    }

    @objc public func variationDetail(experimentKey: Int, defaultVariation: String = "A") -> Decision {
        variationDetail(experimentKey: experimentKey, userId: deviceId, defaultVariation: defaultVariation)
    }

    @objc public func variationDetail(experimentKey: Int, userId: String, defaultVariation: String = "A") -> Decision {
        variationDetail(experimentKey: experimentKey, user: Hackle.user(id: userId), defaultVariation: defaultVariation)
    }

    @objc public func variationDetail(experimentKey: Int, user: User, defaultVariation: String = "A") -> Decision {
        do {
            guard let hackleUser = userResolver.resolveOrNil(user: user) else {
                return Decision.of(variation: defaultVariation, reason: DecisionReason.INVALID_INPUT)
            }
            return try internalApp.experiment(
                experimentKey: Int64(experimentKey),
                user: hackleUser,
                defaultVariationKey: defaultVariation
            )
        } catch let error {
            Log.error("Unexpected error while deciding variation for experiment[\(experimentKey)]: \(String(describing: error))")
            return Decision.of(variation: defaultVariation, reason: DecisionReason.EXCEPTION)
        }
    }

    @objc public func allVariationDetails(user: User) -> [Int: Decision] {
        do {
            guard let hackleUser = userResolver.resolveOrNil(user: user) else {
                return [:]
            }
            return try internalApp.experiments(user: hackleUser)
        } catch let error {
            Log.error("Unexpected error while deciding variations for experiments: \(String(describing: error))")
            return [:]
        }
    }

    @objc public func isFeatureOn(featureKey: Int) -> Bool {
        featureFlagDetail(featureKey: featureKey, userId: deviceId).isOn
    }

    @objc public func isFeatureOn(featureKey: Int, userId: String) -> Bool {
        featureFlagDetail(featureKey: featureKey, userId: userId).isOn
    }

    @objc public func isFeatureOn(featureKey: Int, user: User) -> Bool {
        featureFlagDetail(featureKey: featureKey, user: user).isOn
    }

    @objc public func featureFlagDetail(featureKey: Int) -> FeatureFlagDecision {
        featureFlagDetail(featureKey: featureKey, userId: deviceId)
    }

    @objc public func featureFlagDetail(featureKey: Int, userId: String) -> FeatureFlagDecision {
        featureFlagDetail(featureKey: featureKey, user: Hackle.user(id: userId))
    }

    @objc public func featureFlagDetail(featureKey: Int, user: User) -> FeatureFlagDecision {
        do {
            guard let hackleUser = userResolver.resolveOrNil(user: user) else {
                return FeatureFlagDecision.off(reason: DecisionReason.INVALID_INPUT)
            }
            return try internalApp.featureFlag(
                featureKey: Int64(featureKey),
                user: hackleUser
            )
        } catch {
            Log.error("Unexpected error while deciding feature flag[\(featureKey)]: \(String(describing: error))")
            return FeatureFlagDecision.off(reason: DecisionReason.EXCEPTION)
        }
    }

    @objc public func track(eventKey: String) {
        track(eventKey: eventKey, userId: deviceId)
    }

    @objc public func track(eventKey: String, userId: String) {
        track(eventKey: eventKey, user: Hackle.user(id: userId))
    }

    @objc public func track(eventKey: String, user: User) {
        track(event: Hackle.event(key: eventKey), user: user)
    }

    @objc public func track(event: Event) {
        track(event: event, userId: deviceId)
    }

    @objc public func track(event: Event, userId: String) {
        track(event: event, user: Hackle.user(id: userId))
    }

    @objc public func track(event: Event, user: User) {
        do {
            guard let hackleUser = userResolver.resolveOrNil(user: user) else {
                return
            }
            internalApp.track(
                event: event,
                user: hackleUser
            )
        } catch {
            Log.error("Unexpected exception while tracking event[\(event.key)]: \(String(describing: error))")
        }

    }
}

extension HackleApp {

    private static let hackleDeviceId = "hackle_device_id"

    func initialize(completion: @escaping () -> ()) {
        internalApp.initialize(completion: completion)
    }

    static func create(sdkKey: String, config: HackleConfig) -> HackleApp {

        let sdk = Sdk(key: sdkKey, name: "ios-sdk", version: SdkVersion.CURRENT)
        let httpClient = DefaultHttpClient(sdk: sdk)

        let httpWorkspaceFetcher = DefaultHttpWorkspaceFetcher(
            sdkBaseUrl: config.sdkUrl,
            httpClient: httpClient
        )
        let workspaceFetcher = CachedWorkspaceFetcher(httpWorkspaceFetcher: httpWorkspaceFetcher)

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

        let eventProcessor = DefaultUserEventProcessor(
            eventDedupDeterminer: DefaultExposureEventDedupDeterminer(dedupInterval: config.exposureEventDedupInterval),
            eventQueue: eventQueue,
            eventRepository: eventRepository,
            eventRepositoryMaxSize: HackleConfig.DEFAULT_EVENT_REPOSITORY_MAX_SIZE,
            eventFlushScheduler: DispatchSourceTimerScheduler(),
            eventFlushInterval: config.eventFlushInterval,
            eventFlushThreshold: config.eventFlushThreshold,
            eventFlushMaxBatchSize: config.eventFlushThreshold * 2 + 1,
            eventDispatcher: eventDispatcher
        )

        DefaultAppNotificationObserver.instance.addListener(listener: eventProcessor)

        let internalApp = DefaultHackleInternalApp.create(workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor)
        let device = Device.create()
        let userResolver = DefaultHackleUserResolver(device: device)

        return HackleApp(internalApp: internalApp, userResolver: userResolver, device: device)
    }
}
