//
//  HackleConfig+Deprecate.swift
//  Hackle
//
//  Created by sungwoo.yeo on 7/30/26.
//

import Foundation

extension HackleConfig {
    @available(*, deprecated, message: "Use sessionPolicy.timeoutCondition.timeoutIntervalSeconds instead.")
    var sessionTimeoutInterval: TimeInterval {
        sessionPolicy.timeoutCondition.timeoutIntervalSeconds
    }
}

extension HackleConfigBuilder {
    /// Sets the application mode.
    ///
    /// - Parameter mode: The ``HackleAppMode`` to use
    /// - Returns: This builder instance for method chaining
    @available(*, deprecated, message: "WebView wrapper mode is deprecated and no longer recommended for new integrations.")
    @objc public func mode(_ mode: HackleAppMode) -> HackleConfigBuilder {
        self.appMode = mode
        return self
    }

    /// Sets the session timeout interval in seconds.
    ///
    /// - Parameter sessionTimeoutInterval: The timeout interval after which a session expires
    /// - Returns: This builder instance for method chaining
    @available(*, deprecated, message: "Use sessionPolicy(_:) instead.")
    @objc public func sessionTimeoutIntervalSeconds(_ sessionTimeoutInterval: TimeInterval) -> HackleConfigBuilder {
        self.sessionPolicy = sessionPolicy.withTimeoutInterval(sessionTimeoutInterval)
        return self
    }
}
