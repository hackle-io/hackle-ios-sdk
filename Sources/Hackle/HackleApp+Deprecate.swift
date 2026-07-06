//
//  HackleApp+Deprecate.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/6/26.
//

import Foundation

extension HackleApp {
    @available(*, deprecated, message: "Use variation(experimentKey) without defaultVariation instead.")
    @objc public func variation(experimentKey: Int, defaultVariation: String) -> String {
        variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation).variation
    }

    @available(*, deprecated, message: "Use variationDetail(experimentKey) without defaultVariation instead.")
    @objc public func variationDetail(experimentKey: Int, defaultVariation: String) -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: nil, defaultVariation: defaultVariation, hackleAppContext: .default)
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
