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
    @available(*, deprecated, message: "Use updateUserProperties(operations:) instead.")
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
    ///   - defaultVariation: ignored. `"A"` is always used when the experiment cannot be decided
    /// - Returns: the decided variation for the user, or `"A"` if the experiment cannot be decided
    @available(*, deprecated, message: "Use variation(experimentKey) without defaultVariation instead.")
    @objc public func variation(experimentKey: Int, defaultVariation: String) -> String {
        variation(experimentKey: experimentKey)
    }

    /// Decide the variation to expose to the user for experiment and returns an object that describes the way the variation was decided.
    ///
    /// - Parameters:
    ///   - experimentKey: the unique key for the experiment
    ///   - defaultVariation: ignored. `"A"` is always used when the experiment cannot be decided
    /// - Returns: a ``Decision`` object
    @available(*, deprecated, message: "Use variationDetail(experimentKey) without defaultVariation instead.")
    @objc public func variationDetail(experimentKey: Int, defaultVariation: String) -> Decision {
        variationDetail(experimentKey: experimentKey)
    }

    /// Updates push notification subscription status.
    ///
    /// - Parameter status: the ``HacklePushSubscriptionStatus`` to apply
    @available(*, deprecated, message: "Do not use this method because it does nothing. Use `updatePushSubscriptions(operations)` instead.")
    @objc public func updatePushSubscriptionStatus(status: HacklePushSubscriptionStatus) {
        Log.error("updatePushSubscriptionStatus does nothing. Use updatePushSubscriptions(operations) instead.")
    }
}
