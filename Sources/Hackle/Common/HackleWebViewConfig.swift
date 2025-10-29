//
//  HackleWebViewConfig.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/28/25.
//

import Foundation

/// Configuration for Hackle WebView integration.
@objc public class HackleWebViewConfig: NSObject {
    /// Whether automatic screen tracking is enabled for WebView events.
    @objc public let automaticScreenTracking: Bool

    /// Whether automatic engagement tracking is enabled for WebView events.
    @objc public let automaticEngagementTracking: Bool

    /// Default configuration with all tracking disabled.
    @objc public static let DEFAULT: HackleWebViewConfig = builder().build()

    init(_ builder: HackleWebViewConfigBuilder) {
        self.automaticScreenTracking = builder.automaticScreenTracking
        self.automaticEngagementTracking = builder.automaticEngagementTracking
        super.init()
    }

    /// Creates a new builder instance for constructing HackleWebViewConfig.
    ///
    /// - Returns: A new ``HackleWebViewConfigBuilder`` instance
    @objc public static func builder() -> HackleWebViewConfigBuilder {
        HackleWebViewConfigBuilder()
    }
}

/// Builder for constructing ``HackleWebViewConfig`` instances.
@objc public class HackleWebViewConfigBuilder: NSObject {
    var automaticScreenTracking: Bool = false
    var automaticEngagementTracking: Bool = false

    /// Enables or disables automatic screen tracking for WebView events.
    ///
    /// - Parameter automaticTracking: `true` to enable automatic screen tracking, `false` to disable
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func automaticScreenTracking(_ automaticTracking: Bool) -> HackleWebViewConfigBuilder {
        self.automaticScreenTracking = automaticTracking
        return self
    }

    /// Enables or disables automatic engagement tracking for WebView events.
    ///
    /// - Parameter automaticTracking: `true` to enable automatic engagement tracking, `false` to disable
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func automaticEngagementTracking(_ automaticTracking: Bool) -> HackleWebViewConfigBuilder {
        self.automaticEngagementTracking = automaticTracking
        return self
    }

    /// Builds and returns a ``HackleWebViewConfig`` instance with the configured settings.
    ///
    /// - Returns: A new ``HackleWebViewConfig`` instance
    @objc public func build() -> HackleWebViewConfig {
        return HackleWebViewConfig(self)
    }
}
