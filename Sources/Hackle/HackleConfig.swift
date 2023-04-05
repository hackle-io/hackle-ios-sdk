//
//  HackleConfig.swift
//  Hackle
//
//  Created by yong on 2022/08/12.
//

import Foundation

public class HackleConfig: NSObject {

    var sdkUrl: URL
    var eventUrl: URL
    var monitoringUrl: URL
    var sessionTimeoutInterval: TimeInterval
    var pollingInterval: TimeInterval
    var eventFlushInterval: TimeInterval
    var eventFlushThreshold: Int
    var exposureEventDedupInterval: TimeInterval
    var extra: [String: String]

    init(builder: HackleConfigBuilder) {
        sdkUrl = builder.sdkUrl
        eventUrl = builder.eventUrl
        monitoringUrl = builder.monitoringUrl
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

    @objc public static let DEFAULT: HackleConfig = builder().build()

    @objc public static func builder() -> HackleConfigBuilder {
        HackleConfigBuilder()
    }

    func get(_ key: String) -> String? {
        extra[key]
    }
}

public class HackleConfigBuilder: NSObject {

    var sdkUrl: URL = URL(string: "https://client-sdk.hackle.io")!
    var eventUrl: URL = URL(string: "https://event.hackle.io")!
    var monitoringUrl: URL = URL(string: "https://monitoring.hackle.io")!

    var sessionTimeoutInterval: TimeInterval = HackleConfig.DEFAULT_SESSION_TIMEOUT_INTERVAL

    var pollingInterval: TimeInterval = HackleConfig.NO_POLLING

    var eventFlushInterval: TimeInterval = HackleConfig.DEFAULT_EVENT_FLUSH_INTERVAL
    var eventFlushThreshold: Int = HackleConfig.DEFAULT_EVENT_FLUSH_THRESHOLD

    var exposureEventDedupInterval: TimeInterval = HackleConfig.DEFAULT_EXPOSURE_EVENT_DEDUP_INTERVAL

    var extra: [String: String] = [:]

    @objc public func sdkUrl(_ sdkUrl: URL) -> HackleConfigBuilder {
        self.sdkUrl = sdkUrl
        return self
    }

    @objc public func eventUrl(_ eventUrl: URL) -> HackleConfigBuilder {
        self.eventUrl = eventUrl
        return self
    }

    @objc public func monitoringUrl(_ monitoringUrl: URL) -> HackleConfigBuilder {
        self.monitoringUrl = monitoringUrl
        return self
    }

    @objc public func sessionTimeoutIntervalSeconds(_ sessionTimeoutInterval: TimeInterval) -> HackleConfigBuilder {
        self.sessionTimeoutInterval = sessionTimeoutInterval
        return self
    }

    @objc public func pollingIntervalSeconds(_ pollingInterval: TimeInterval) -> HackleConfigBuilder {
        self.pollingInterval = pollingInterval
        return self
    }

    @objc public func eventFlushIntervalSeconds(_ eventFlushInterval: TimeInterval) -> HackleConfigBuilder {
        self.eventFlushInterval = eventFlushInterval
        return self
    }

    @objc public func eventFlushThreshold(_ eventFlushThreshold: Int) -> HackleConfigBuilder {
        self.eventFlushThreshold = eventFlushThreshold
        return self
    }

    @objc public func exposureEventDedupIntervalSeconds(_ exposureEventDedupInterval: TimeInterval) -> HackleConfigBuilder {
        self.exposureEventDedupInterval = exposureEventDedupInterval
        return self
    }

    @objc public func add(_ key: String, _ value: String) -> HackleConfigBuilder {
        self.extra[key] = value
        return self
    }

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

        if exposureEventDedupInterval != HackleConfig.NO_DEDUP && !(1...3600).contains(exposureEventDedupInterval) {
            Log.info("Exposure event dedup interval is outside allowed range[1s..3600s]. Setting to default value[60s].")
            self.exposureEventDedupInterval = HackleConfig.DEFAULT_EXPOSURE_EVENT_DEDUP_INTERVAL
        }

        return HackleConfig(builder: self)
    }
}
