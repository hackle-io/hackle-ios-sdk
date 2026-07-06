//
//  HackleApp+Deprecate.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/6/26.
//

import Foundation

extension HackleApp {
    /// Sets or replaces the current user.
    ///
    /// - Parameter user: the ``User`` to set
    @available(*, deprecated, message: "Use async setUser(user:) or setUser(user:completion:) instead.")
    @objc public func setUser(user: User) {
        setUser(user: user, completion: {})
    }

    /// Sets the userId for the current user.
    ///
    /// - Parameter userId: the userId to set for the user. Can be null to identify an anonymous user
    @available(*, deprecated, message: "Use async setUserId(userId:) or setUserId(userId:completion:) instead.")
    @objc public func setUserId(userId: String?) {
        setUserId(userId: userId, completion: {})
    }

    /// Sets a custom device ID.
    ///
    /// - Parameter deviceId: the custom device ID to set
    @available(*, deprecated, message: "Use async setDeviceId(deviceId:) or setDeviceId(deviceId:completion:) instead.")
    @objc public func setDeviceId(deviceId: String) {
        setDeviceId(deviceId: deviceId, completion: {})
    }

    /// Sets a single user property.
    ///
    /// - Parameters:
    ///   - key: the key of the property
    ///   - value: the value of the property
    @available(*, deprecated, message: "Use async setUserProperty(key:value:) or setUserProperty(key:value:completion:) instead.")
    @objc public func setUserProperty(key: String, value: Any?) {
        let operations = PropertyOperations.builder()
            .set(key, value)
            .build()
        updateUserProperties(operations: operations, completion: {})
    }

    /// Updates user properties with a set of operations.
    ///
    /// - Parameter operations: a set of ``PropertyOperations`` to apply to user properties
    @available(*, deprecated, message: "Use async updateUserProperties(operations:) or updateUserProperties(operations:completion:) instead.")
    @objc public func updateUserProperties(operations: PropertyOperations) {
        updateUserProperties(operations: operations, completion: {})
    }

    /// Resets the current user.
    @available(*, deprecated, message: "Use async resetUser() or resetUser(completion:) instead.")
    @objc public func resetUser() {
        resetUser(completion: {})
    }

    /// Sets the phone number for the current user.
    ///
    /// - Parameter phoneNumber: the phone number to set
    @available(*, deprecated, message: "Use async setPhoneNumber(phoneNumber:) or setPhoneNumber(phoneNumber:completion:) instead.")
    @objc public func setPhoneNumber(phoneNumber: String) {
        setPhoneNumber(phoneNumber: phoneNumber, completion: {})
    }

    /// Removes the phone number from the current user.
    @available(*, deprecated, message: "Use async unsetPhoneNumber() or unsetPhoneNumber(completion:) instead.")
    @objc public func unsetPhoneNumber() {
        unsetPhoneNumber(completion: {})
    }

    /// Decide the variation to expose to the user for experiment.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key of the experiment
    ///   - defaultVariation: the default variation to return if the experiment cannot be decided
    /// - Returns: the decided variation for the user, or defaultVariation
    @available(*, deprecated, message: "Use variation(experimentKey) without defaultVariation instead.")
    @objc public func variation(experimentKey: Int, defaultVariation: String) -> String {
        variationDetail(experimentKey: experimentKey, defaultVariation: defaultVariation).variation
    }

    /// Decide the variation to expose to the user for experiment and returns an object that describes the way the variation was decided.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key for the experiment
    ///   - defaultVariation: the default variation to return if the experiment cannot be decided
    /// - Returns: a ``Decision`` object
    @available(*, deprecated, message: "Use variationDetail(experimentKey) without defaultVariation instead.")
    @objc public func variationDetail(experimentKey: Int, defaultVariation: String) -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: nil, defaultVariation: defaultVariation, hackleAppContext: .default)
    }

    /// Decide the variation to expose to the user for experiment.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key of the experiment
    ///   - userId: the identifier of the user to decide the variation for
    ///   - defaultVariation: the default variation to return if the experiment cannot be decided
    /// - Returns: the decided variation for the user, or defaultVariation
    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    @objc public func variation(experimentKey: Int, userId: String, defaultVariation: String = "A") -> String {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: Hackle.user(id: userId), defaultVariation: defaultVariation, hackleAppContext: .default).variation
    }

    /// Decide the variation to expose to the user for experiment.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key of the experiment
    ///   - user: the ``User`` to decide the variation for
    ///   - defaultVariation: the default variation to return if the experiment cannot be decided
    /// - Returns: the decided variation for the user, or defaultVariation
    @available(*, deprecated, message: "Use variation(experimentKey) with setUser(user) instead.")
    @objc public func variation(experimentKey: Int, user: User, defaultVariation: String = "A") -> String {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: user, defaultVariation: defaultVariation, hackleAppContext: .default).variation
    }

    /// Decide the variation to expose to the user for experiment and returns an object that describes the way the variation was decided.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key for the experiment
    ///   - userId: the identifier of the user to decide the variation for
    ///   - defaultVariation: the default variation to return if the experiment cannot be decided
    /// - Returns: a ``Decision`` object
    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    @objc public func variationDetail(experimentKey: Int, userId: String, defaultVariation: String = "A") -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: Hackle.user(id: userId), defaultVariation: defaultVariation, hackleAppContext: .default)
    }

    /// Decide the variation to expose to the user for experiment and returns an object that describes the way the variation was decided.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key for the experiment
    ///   - user: the ``User`` to decide the variation for
    ///   - defaultVariation: the default variation to return if the experiment cannot be decided
    /// - Returns: a ``Decision`` object
    @available(*, deprecated, message: "Use variationDetail(experimentKey) with setUser(user) instead,")
    @objc public func variationDetail(experimentKey: Int, user: User, defaultVariation: String = "A") -> Decision {
        hackleAppCore.variationDetail(experimentKey: experimentKey, user: user, defaultVariation: defaultVariation, hackleAppContext: .default)
    }

    /// Decide the variations for all experiments and returns a map of decision results.
    ///
    /// - Parameter user: the ``User`` to decide the variations for
    /// - Returns: a dictionary where key is experimentKey and value is ``Decision`` result
    @available(*, deprecated, message: "Use allVariationDetails() with setUser(user) instead.")
    @objc public func allVariationDetails(user: User) -> [Int: Decision] {
        hackleAppCore.allVariationDetails(user: user, hackleAppContext: .default)
    }

    /// Decide whether the feature is turned on to the user.
    ///
    /// - Parameters:
    ///   - featureKey: the unique key for the feature
    ///   - userId: the identifier of the user to decide the feature flag for
    /// - Returns: True if the feature is on, False if the feature is off
    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    @objc public func isFeatureOn(featureKey: Int, userId: String) -> Bool {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: Hackle.user(id: userId), hackleAppContext: .default).isOn
    }

    /// Decide whether the feature is turned on to the user.
    ///
    /// - Parameters:
    ///   - featureKey: the unique key for the feature
    ///   - user: the ``User`` to decide the feature flag for
    /// - Returns: True if the feature is on, False if the feature is off
    @available(*, deprecated, message: "Use isFeatureOn(featureKey) with setUser(user) instead.")
    @objc public func isFeatureOn(featureKey: Int, user: User) -> Bool {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: user, hackleAppContext: .default).isOn
    }

    /// Decide whether the feature is turned on to the user and returns an object that describes the way the flag was decided.
    ///
    /// - Parameters:
    ///   - featureKey: the unique key for the feature
    ///   - userId: the identifier of the user to decide the feature flag for
    /// - Returns: a ``FeatureFlagDecision`` object
    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    @objc public func featureFlagDetail(featureKey: Int, userId: String) -> FeatureFlagDecision {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: Hackle.user(id: userId), hackleAppContext: .default)
    }

    /// Decide whether the feature is turned on to the user and returns an object that describes the way the flag was decided.
    ///
    /// - Parameters:
    ///   - featureKey: the unique key for the feature
    ///   - user: the ``User`` to decide the feature flag for
    /// - Returns: a ``FeatureFlagDecision`` object
    @available(*, deprecated, message: "Use featureFlagDetail(featureKey) with setUser(user) instead.")
    @objc public func featureFlagDetail(featureKey: Int, user: User) -> FeatureFlagDecision {
        hackleAppCore.featureFlagDetail(featureKey: featureKey, user: user, hackleAppContext: .default)
    }

    /// Records the event that occurred by the user.
    ///
    /// - Parameters:
    ///   - eventKey: the unique key of the event that occurred
    ///   - userId: the identifier of the user who triggered the event
    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    @objc public func track(eventKey: String, userId: String) {
        hackleAppCore.track(event: Hackle.event(key: eventKey), user: Hackle.user(id: userId), hackleAppContext: .default)
    }

    /// Records the event that occurred by the user.
    ///
    /// - Parameters:
    ///   - eventKey: the unique key of the event that occurred
    ///   - user: the ``User`` who triggered the event
    @available(*, deprecated, message: "Use track(eventKey) with setUser(user) instead.")
    @objc public func track(eventKey: String, user: User) {
        hackleAppCore.track(event: Hackle.event(key: eventKey), user: user, hackleAppContext: .default)
    }

    /// Records the event that occurred by the user.
    ///
    /// - Parameters:
    ///   - event: the ``Event`` that occurred
    ///   - userId: the identifier of the user who triggered the event
    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    @objc public func track(event: Event, userId: String) {
        hackleAppCore.track(event: event, user: Hackle.user(id: userId), hackleAppContext: .default)
    }

    /// Records the event that occurred by the user.
    ///
    /// - Parameters:
    ///   - event: the ``Event`` that occurred
    ///   - user: the ``User`` who triggered the event
    @available(*, deprecated, message: "Use track(event) with setUser(user) instead.")
    @objc public func track(event: Event, user: User) {
        hackleAppCore.track(event: event, user: user, hackleAppContext: .default)
    }

    /// Returns an instance of Hackle Remote Config.
    ///
    /// - Parameter user: the ``User`` to evaluate the remote config for
    /// - Returns: a ``HackleRemoteConfig`` instance
    @available(*, deprecated, message: "Use remoteConfig() with setUser(user) instead.")
    @objc public func remoteConfig(user: User) -> HackleRemoteConfig {
        DefaultRemoteConfig(hackleAppCore: hackleAppCore, user: user)
    }

    /// Updates push notification subscription status.
    ///
    /// - Parameter status: the ``HacklePushSubscriptionStatus`` to apply
    @available(*, deprecated, message: "Do not use this method because it does nothing. Use `updatePushSubscriptions(operations)` instead.")
    @objc public func updatePushSubscriptionStatus(status: HacklePushSubscriptionStatus) {
        Log.error("updatePushSubscriptionStatus does nothing. Use updatePushSubscriptions(operations) instead.")
    }
}
