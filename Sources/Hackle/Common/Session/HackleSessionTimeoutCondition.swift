//
//  HackleSessionTimeoutCondition.swift
//  Hackle
//

import Foundation

@objc public class HackleSessionTimeoutCondition: NSObject {

    @objc public let timeoutIntervalSeconds: TimeInterval
    @objc public let onForeground: Bool
    @objc public let onBackground: Bool
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

    @objc public static func builder() -> HackleSessionTimeoutConditionBuilder {
        HackleSessionTimeoutConditionBuilder()
    }

    @objc public func toBuilder() -> HackleSessionTimeoutConditionBuilder {
        HackleSessionTimeoutConditionBuilder()
            .timeoutIntervalSeconds(timeoutIntervalSeconds)
            .onForeground(onForeground)
            .onBackground(onBackground)
            .onApplicationStateChange(onApplicationStateChange)
    }

    static let DEFAULT_SESSION_TIMEOUT_INTERVAL: TimeInterval = 1800 // 30m

    @objc public static let DEFAULT = HackleSessionTimeoutCondition(
        timeoutIntervalSeconds: DEFAULT_SESSION_TIMEOUT_INTERVAL,
        onForeground: false,
        onBackground: true,
        onApplicationStateChange: true
    )
}

@objc public class HackleSessionTimeoutConditionBuilder: NSObject {

    private var _timeoutIntervalSeconds: TimeInterval = HackleSessionTimeoutCondition.DEFAULT_SESSION_TIMEOUT_INTERVAL
    private var _onForeground: Bool = false
    private var _onBackground: Bool = true
    private var _onApplicationStateChange: Bool = true

    @objc @discardableResult
    public func timeoutIntervalSeconds(_ timeoutIntervalSeconds: TimeInterval) -> HackleSessionTimeoutConditionBuilder {
        self._timeoutIntervalSeconds = timeoutIntervalSeconds
        return self
    }

    @objc @discardableResult
    public func onForeground(_ onForeground: Bool) -> HackleSessionTimeoutConditionBuilder {
        self._onForeground = onForeground
        return self
    }

    @objc @discardableResult
    public func onBackground(_ onBackground: Bool) -> HackleSessionTimeoutConditionBuilder {
        self._onBackground = onBackground
        return self
    }

    @objc @discardableResult
    public func onApplicationStateChange(_ onApplicationStateChange: Bool) -> HackleSessionTimeoutConditionBuilder {
        self._onApplicationStateChange = onApplicationStateChange
        return self
    }

    @objc public func build() -> HackleSessionTimeoutCondition {
        HackleSessionTimeoutCondition(
            timeoutIntervalSeconds: _timeoutIntervalSeconds,
            onForeground: _onForeground,
            onBackground: _onBackground,
            onApplicationStateChange: _onApplicationStateChange
        )
    }
}
