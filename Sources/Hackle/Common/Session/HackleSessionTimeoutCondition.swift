//
//  HackleSessionTimeoutCondition.swift
//  Hackle
//

import Foundation

/// Defines the conditions under which a session times out.
@objc public final class HackleSessionTimeoutCondition: NSObject, Sendable {

    /// The session timeout interval in seconds.
    ///
    /// If no event occurs within this interval, the session is considered timed out.
    /// The default value is 1800 seconds (30 minutes).
    @objc public let timeoutIntervalSeconds: TimeInterval

    /// Whether to check for session timeout while the app is in the foreground.
    ///
    /// Defaults to `false`.
    @objc public let onForeground: Bool

    /// Whether to check for session timeout while the app is in the background.
    ///
    /// Defaults to `true`.
    @objc public let onBackground: Bool

    /// Whether to check for session timeout on application state changes (foreground/background transitions).
    ///
    /// Defaults to `true`.
    @objc public let onApplicationStateChange: Bool

    init(
        timeoutIntervalSeconds: TimeInterval,
        onForeground: Bool,
        onBackground: Bool,
        onApplicationStateChange: Bool
    ) {
        self.timeoutIntervalSeconds = timeoutIntervalSeconds
        self.onForeground = onForeground
        self.onBackground = onBackground
        self.onApplicationStateChange = onApplicationStateChange
        super.init()
    }

    /// Creates a new ``HackleSessionTimeoutConditionBuilder``.
    ///
    /// - Returns: A new builder instance with default values
    @objc public static func builder() -> HackleSessionTimeoutConditionBuilder {
        HackleSessionTimeoutConditionBuilder()
    }

    /// Creates a new ``HackleSessionTimeoutConditionBuilder`` pre-populated with this condition's values.
    ///
    /// - Returns: A builder instance initialized with this condition's current configuration
    @objc public func toBuilder() -> HackleSessionTimeoutConditionBuilder {
        HackleSessionTimeoutConditionBuilder()
            .timeoutIntervalSeconds(timeoutIntervalSeconds)
            .onForeground(onForeground)
            .onBackground(onBackground)
            .onApplicationStateChange(onApplicationStateChange)
    }

    static let defaultSessionTimeoutInterval: TimeInterval = 1800 // 30m

    /// The default timeout condition.
    ///
    /// - Timeout interval: 1800 seconds (30 minutes)
    /// - On foreground: `false`
    /// - On background: `true`
    /// - On application state change: `true`
    @objc public static let `default` = HackleSessionTimeoutCondition(
        timeoutIntervalSeconds: defaultSessionTimeoutInterval,
        onForeground: false,
        onBackground: true,
        onApplicationStateChange: true
    )
}

/// Builder for creating ``HackleSessionTimeoutCondition`` instances.
@objc public class HackleSessionTimeoutConditionBuilder: NSObject {

    private var timeoutIntervalSeconds: TimeInterval = HackleSessionTimeoutCondition.defaultSessionTimeoutInterval
    private var onForeground: Bool = false
    private var onBackground: Bool = true
    private var onApplicationStateChange: Bool = true

    /// Sets the session timeout interval in seconds.
    ///
    /// - Parameter timeoutIntervalSeconds: The timeout interval. Must be positive.
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func timeoutIntervalSeconds(_ timeoutIntervalSeconds: TimeInterval) -> HackleSessionTimeoutConditionBuilder {
        self.timeoutIntervalSeconds = timeoutIntervalSeconds
        return self
    }

    /// Sets whether to check for session timeout while the app is in the foreground.
    ///
    /// - Parameter onForeground: `true` to enable foreground timeout checks
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func onForeground(_ onForeground: Bool) -> HackleSessionTimeoutConditionBuilder {
        self.onForeground = onForeground
        return self
    }

    /// Sets whether to check for session timeout while the app is in the background.
    ///
    /// - Parameter onBackground: `true` to enable background timeout checks
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func onBackground(_ onBackground: Bool) -> HackleSessionTimeoutConditionBuilder {
        self.onBackground = onBackground
        return self
    }

    /// Sets whether to check for session timeout on application state changes.
    ///
    /// - Parameter onApplicationStateChange: `true` to enable timeout checks on foreground/background transitions
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func onApplicationStateChange(_ onApplicationStateChange: Bool) -> HackleSessionTimeoutConditionBuilder {
        self.onApplicationStateChange = onApplicationStateChange
        return self
    }

    /// Builds the ``HackleSessionTimeoutCondition`` instance with the specified settings.
    ///
    /// - Returns: A configured ``HackleSessionTimeoutCondition`` instance
    @objc public func build() -> HackleSessionTimeoutCondition {
        HackleSessionTimeoutCondition(
            timeoutIntervalSeconds: timeoutIntervalSeconds,
            onForeground: onForeground,
            onBackground: onBackground,
            onApplicationStateChange: onApplicationStateChange
        )
    }
}
