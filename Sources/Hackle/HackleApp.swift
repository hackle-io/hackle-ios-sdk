//
// Created by yong on 2020/12/11.
//

import Foundation

/// Entry point of Hackle Sdk.
@objc public final class HackleApp: NSObject {

    private let internalApp: HackleInternalApp

    @objc public var deviceId: String {
        get {
            UserDefaults.standard.computeIfAbsent(key: HackleApp.hackleDeviceId) { _ in
                UUID().uuidString
            }
        }
    }

    init(internalApp: HackleInternalApp) {
        self.internalApp = internalApp
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
            return try internalApp.experiment(experimentKey: Int64(experimentKey), user: user, defaultVariationKey: defaultVariation)
        } catch let error {
            Log.error("Unexpected error while deciding variation for experiment[\(experimentKey)]: \(String(describing: error))")
            return Decision.of(variation: defaultVariation, reason: DecisionReason.EXCEPTION)
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
            return try internalApp.featureFlag(featureKey: Int64(featureKey), user: user)
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
        internalApp.track(event: event, user: user)
    }
}

extension HackleApp {

    private static let hackleDeviceId = "hackle_device_id"

    func initialize(completion: @escaping () -> ()) {
        internalApp.initialize(completion: completion)
    }

    static func create(sdkKey: String) -> HackleApp {

        let sdk = Sdk(key: sdkKey, name: "ios-sdk", version: SdkVersion.CURRENT)
        let httpClient = DefaultHttpClient(sdk: sdk)

        let httpWorkspaceFetcher = DefaultHttpWorkspaceFetcher(
            sdkBaseUrl: URL(string: "https://sdk.hackle.io")!,
            httpClient: httpClient
        )
        let workspaceFetcher = CachedWorkspaceFetcher(httpWorkspaceFetcher: httpWorkspaceFetcher)

        let eventDispatcher = DefaultUserEventDispatcher(
            eventBaseUrl: URL(string: "https://event.hackle.io")!,
            httpClient: httpClient
        )
        let eventProcessor = DefaultUserEventProcessor(
            eventQueue: ConcurrentArray(),
            eventDispatcher: eventDispatcher,
            eventDispatchSize: 10,
            flushScheduler: DispatchSourceTimerScheduler(),
            flushInterval: 60
        )

        DefaultAppNotificationObserver.instance.addListener(listener: eventProcessor)

        let internalApp = DefaultHackleInternalApp.create(workspaceFetcher: workspaceFetcher, eventProcessor: eventProcessor)

        return HackleApp(internalApp: internalApp)
    }
}
