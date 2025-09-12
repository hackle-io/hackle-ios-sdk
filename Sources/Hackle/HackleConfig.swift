//
//  HackleConfig.swift
//  Hackle
//
//  Created by yong on 2022/08/12.
//

import Foundation

/// Configuration options for the Hackle SDK.
///
/// Use ``HackleConfigBuilder`` to create and customize configuration settings for the SDK.
public class HackleConfig: NSObject {

    var sdkUrl: URL
    var eventUrl: URL
    var apiUrl: URL
    var monitoringUrl: URL
    var mode: HackleAppMode
    var automaticScreenTracking: Bool
    var sessionTracking: Bool
    var sessionTimeoutInterval: TimeInterval
    var pollingInterval: TimeInterval
    var eventFlushInterval: TimeInterval
    var eventFlushThreshold: Int
    var exposureEventDedupInterval: TimeInterval
    var extra: [String: String]

    init(builder: HackleConfigBuilder) {
        sdkUrl = builder.sdkUrl
        eventUrl = builder.eventUrl
        apiUrl = builder.apiUrl
        monitoringUrl = builder.monitoringUrl
        mode = builder.mode
        automaticScreenTracking = builder.automaticScreenTracking
        sessionTracking = (mode == .native && builder.sessionTracking)
        sessionTimeoutInterval = builder.sessionTimeoutInterval
        pollingInterval = builder.pollingInterval
        eventFlushInterval = builder.eventFlushInterval
        eventFlushThreshold = builder.eventFlushThreshold
        exposureEventDedupInterval = builder.exposureEventDedupInterval
        extra = builder.extra
        super.init()
    }

    static let NO_POLLING: TimeInterval = -1
    static let NO_DEDUP: TimeInterval = -1

    static let DEFAULT_SESSION_TIMEOUT_INTERVAL: TimeInterval = 1800 // 30m
    static let DEFAULT_EVENT_FLUSH_INTERVAL: TimeInterval = 10
    static let DEFAULT_EVENT_FLUSH_THRESHOLD = 10
    static let DEFAULT_EVENT_REPOSITORY_MAX_SIZE = 1000
    static let DEFAULT_EXPOSURE_EVENT_DEDUP_INTERVAL: TimeInterval = 60
    static let EXPOSURE_EVENT_DEDUP_INTERVAL_LIMIT: TimeInterval = 60 * 60 * 24 // 24 hours

    /// Default configuration with standard settings.
    @objc public static let DEFAULT: HackleConfig = builder().build()

    /// Creates a new configuration builder.
    ///
    /// - Returns: A ``HackleConfigBuilder`` instance for creating custom configurations
    @objc public static func builder() -> HackleConfigBuilder {
        HackleConfigBuilder()
    }

    func get(_ key: String) -> String? {
        extra[key]
    }
}

/// Builder for creating ``HackleConfig`` instances with custom settings.
public class HackleConfigBuilder: NSObject {

    var sdkUrl: URL = URL(string: "https://sdk-api.hackle.io")!
    var eventUrl: URL = URL(string: "https://event-api.hackle.io")!
    var apiUrl: URL = URL(string: "https://api.hackle.io")!
    var monitoringUrl: URL = URL(string: "https://monitoring.hackle.io")!

    var mode: HackleAppMode = .native

    var automaticScreenTracking: Bool = true

    var sessionTracking: Bool = true
    var sessionTimeoutInterval: TimeInterval = HackleConfig.DEFAULT_SESSION_TIMEOUT_INTERVAL

    var pollingInterval: TimeInterval = HackleConfig.NO_POLLING

    var eventFlushInterval: TimeInterval = HackleConfig.DEFAULT_EVENT_FLUSH_INTERVAL
    var eventFlushThreshold: Int = HackleConfig.DEFAULT_EVENT_FLUSH_THRESHOLD

    var exposureEventDedupInterval: TimeInterval = HackleConfig.DEFAULT_EXPOSURE_EVENT_DEDUP_INTERVAL

    var extra: [String: String] = [:]

    /// Sets the SDK API endpoint URL.
    ///
    /// - Parameter sdkUrl: The URL for the Hackle SDK API
    /// - Returns: This builder instance for method chaining
    @objc public func sdkUrl(_ sdkUrl: URL) -> HackleConfigBuilder {
        self.sdkUrl = sdkUrl
        return self
    }

    /// Sets the event API endpoint URL.
    ///
    /// - Parameter eventUrl: The URL for the Hackle event API
    /// - Returns: This builder instance for method chaining
    @objc public func eventUrl(_ eventUrl: URL) -> HackleConfigBuilder {
        self.eventUrl = eventUrl
        return self
    }

    /// Sets the general API endpoint URL.
    ///
    /// - Parameter apiUrl: The URL for the Hackle general API
    /// - Returns: This builder instance for method chaining
    @objc public func apiUrl(_ apiUrl: URL) -> HackleConfigBuilder {
        self.apiUrl = apiUrl
        return self
    }

    /// Sets the monitoring endpoint URL.
    ///
    /// - Parameter monitoringUrl: The URL for the Hackle monitoring API
    /// - Returns: This builder instance for method chaining
    @objc public func monitoringUrl(_ monitoringUrl: URL) -> HackleConfigBuilder {
        self.monitoringUrl = monitoringUrl
        return self
    }

    /// Sets the application mode.
    ///
    /// - Parameter mode: The ``HackleAppMode`` to use
    /// - Returns: This builder instance for method chaining
    @objc public func mode(_ mode: HackleAppMode) -> HackleConfigBuilder {
        self.mode = mode
        return self
    }

    /// Enables or disables automatic screen tracking.
    ///
    /// - Parameter automaticScreenTracking: Whether to automatically track screen views
    /// - Returns: This builder instance for method chaining
    @objc public func automaticScreenTracking(_ automaticScreenTracking: Bool) -> HackleConfigBuilder {
        self.automaticScreenTracking = automaticScreenTracking
        return self
    }

    /// Sets the session timeout interval in seconds.
    ///
    /// - Parameter sessionTimeoutInterval: The timeout interval after which a session expires
    /// - Returns: This builder instance for method chaining
    @objc public func sessionTimeoutIntervalSeconds(_ sessionTimeoutInterval: TimeInterval) -> HackleConfigBuilder {
        self.sessionTimeoutInterval = sessionTimeoutInterval
        return self
    }

    /// Sets the configuration polling interval in seconds.
    ///
    /// - Parameter pollingInterval: The interval at which to poll for configuration updates
    /// - Returns: This builder instance for method chaining
    @objc public func pollingIntervalSeconds(_ pollingInterval: TimeInterval) -> HackleConfigBuilder {
        self.pollingInterval = pollingInterval
        return self
    }

    /// Sets the event flush interval in seconds.
    ///
    /// - Parameter eventFlushInterval: The interval at which to flush events to the server
    /// - Returns: This builder instance for method chaining
    @objc public func eventFlushIntervalSeconds(_ eventFlushInterval: TimeInterval) -> HackleConfigBuilder {
        self.eventFlushInterval = eventFlushInterval
        return self
    }

    /// Sets the event flush threshold.
    ///
    /// - Parameter eventFlushThreshold: The number of events that triggers an automatic flush
    /// - Returns: This builder instance for method chaining
    @objc public func eventFlushThreshold(_ eventFlushThreshold: Int) -> HackleConfigBuilder {
        self.eventFlushThreshold = eventFlushThreshold
        return self
    }

    /// Sets the exposure event deduplication interval in seconds.
    ///
    /// - Parameter exposureEventDedupInterval: The interval for deduplicating exposure events
    /// - Returns: This builder instance for method chaining
    @objc public func exposureEventDedupIntervalSeconds(_ exposureEventDedupInterval: TimeInterval) -> HackleConfigBuilder {
        self.exposureEventDedupInterval = exposureEventDedupInterval
        return self
    }

    /// Adds an extra configuration parameter.
    ///
    /// - Parameters:
    ///   - key: The configuration key
    ///   - value: The configuration value
    /// - Returns: This builder instance for method chaining
    @objc public func add(_ key: String, _ value: String) -> HackleConfigBuilder {
        self.extra[key] = value
        return self
    }

    /// Builds the ``HackleConfig`` instance with the specified settings.
    ///
    /// - Returns: A configured ``HackleConfig`` instance
    @objc public func build() -> HackleConfig {

        if pollingInterval != HackleConfig.NO_POLLING && pollingInterval < 60 {
            Log.info("Polling interval is outside allowed value [min 60s]. Setting to min value[60s]")
            self.pollingInterval = 60
        }

        if !(1...60).contains(eventFlushInterval) {
            Log.info("Event flush interval is outside allowed range[1s..60s]. Setting to default value[10s]")
            self.eventFlushInterval = HackleConfig.DEFAULT_EVENT_FLUSH_INTERVAL
        }

        if !(5...30).contains(eventFlushThreshold) {
            Log.info("Event flush threshold is outside allowed range[5..30]. Setting to default value[10]")
            self.eventFlushThreshold = HackleConfig.DEFAULT_EVENT_FLUSH_THRESHOLD
        }

        if exposureEventDedupInterval != HackleConfig.NO_DEDUP &&
            !(1...HackleConfig.EXPOSURE_EVENT_DEDUP_INTERVAL_LIMIT).contains(exposureEventDedupInterval) {
            Log.info("Exposure event dedup interval is outside allowed range[1s..\(HackleConfig.EXPOSURE_EVENT_DEDUP_INTERVAL_LIMIT)s]. Setting to default value[60s].")
            self.exposureEventDedupInterval = HackleConfig.DEFAULT_EXPOSURE_EVENT_DEDUP_INTERVAL
        }

        return HackleConfig(builder: self)
    }
}

/// Application mode for the Hackle SDK.
@objc public enum HackleAppMode: Int {
    /// Native iOS application mode
    case native
    /// WebView wrapper mode for certain web applications
    case web_view_wrapper
}

extension HackleAppMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .native:
            return "native"
        case .web_view_wrapper:
            return "web_view_wrapper"
        }
    }
}
