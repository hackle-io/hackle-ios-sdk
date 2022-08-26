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
    var exposureEventDedupInterval: TimeInterval

    init(sdkUrl: URL, eventUrl: URL, exposureEventDedupInterval: TimeInterval) {
        self.sdkUrl = sdkUrl
        self.eventUrl = eventUrl
        self.exposureEventDedupInterval = exposureEventDedupInterval
        super.init()
    }

    @objc public static let DEFAULT: HackleConfig = builder().build()

    @objc public static func builder() -> HackleConfigBuilder {
        HackleConfigBuilder()
    }
}

public class HackleConfigBuilder: NSObject {

    var sdkUrl: URL = URL(string: "https://sdk.hackle.io")!
    var eventUrl: URL = URL(string: "https://event.hackle.io")!
    var exposureEventDedupInterval: TimeInterval = -1

    @objc public func sdkUrl(_ sdkUrl: URL) -> HackleConfigBuilder {
        self.sdkUrl = sdkUrl
        return self
    }

    @objc public func eventUrl(_ eventUrl: URL) -> HackleConfigBuilder {
        self.eventUrl = eventUrl
        return self
    }

    @objc public func exposureEventDedupInterval(_ exposureEventDedupInterval: TimeInterval) -> HackleConfigBuilder {
        self.exposureEventDedupInterval = exposureEventDedupInterval
        return self
    }

    @objc public func build() -> HackleConfig {

        if (exposureEventDedupInterval != -1) {
            if (exposureEventDedupInterval < 1 || exposureEventDedupInterval > 3600) {
                Log.info("Exposure event dedup interval is outside allowed range[1s..3600s]. Setting to default value[no dedup].")
                self.exposureEventDedupInterval = -1
            }
        }

        return HackleConfig(
            sdkUrl: sdkUrl,
            eventUrl: eventUrl,
            exposureEventDedupInterval: exposureEventDedupInterval
        )
    }
}
