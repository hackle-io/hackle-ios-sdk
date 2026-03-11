//
//  HackleSessionPolicy.swift
//  Hackle
//

import Foundation

/// Defines the session management policy for the Hackle SDK.
@objc public final class HackleSessionPolicy: NSObject, Sendable {

    /// The condition that determines whether an existing session should be persisted when the user changes.
    @objc public let persistCondition: HackleSessionPersistCondition

    /// The condition that determines when a session times out.
    @objc public let timeoutCondition: HackleSessionTimeoutCondition

    init(
        persistCondition: HackleSessionPersistCondition,
        timeoutCondition: HackleSessionTimeoutCondition
    ) {
        self.persistCondition = persistCondition
        self.timeoutCondition = timeoutCondition
        super.init()
    }

    /// Creates a new ``HackleSessionPolicyBuilder``.
    ///
    /// - Returns: A new builder instance with default values
    @objc public static func builder() -> HackleSessionPolicyBuilder {
        HackleSessionPolicyBuilder()
    }

    /// Creates a new ``HackleSessionPolicyBuilder`` pre-populated with this policy's values.
    ///
    /// - Returns: A builder instance initialized with this policy's current configuration
    @objc public func toBuilder() -> HackleSessionPolicyBuilder {
        HackleSessionPolicyBuilder()
            .persistCondition(persistCondition)
            .timeoutCondition(timeoutCondition)
    }

    /// The default session policy.
    ///
    /// Uses ``HackleSessionPersistCondition/ALWAYS_NEW_SESSION`` for persist condition
    /// and ``HackleSessionTimeoutCondition/DEFAULT`` for timeout condition.
    @objc public static let DEFAULT = HackleSessionPolicy(
        persistCondition: .ALWAYS_NEW_SESSION,
        timeoutCondition: .DEFAULT
    )

    func withTimeoutInterval(_ interval: TimeInterval) -> HackleSessionPolicy {
        toBuilder()
            .timeoutCondition(
                timeoutCondition.toBuilder()
                    .timeoutIntervalSeconds(interval)
                    .build()
            )
            .build()
    }
}

/// Builder for creating ``HackleSessionPolicy`` instances.
@objc public class HackleSessionPolicyBuilder: NSObject {

    private var persistCondition: HackleSessionPersistCondition = .ALWAYS_NEW_SESSION
    private var timeoutCondition: HackleSessionTimeoutCondition = .DEFAULT

    /// Sets the session persist condition.
    ///
    /// - Parameter persistCondition: The ``HackleSessionPersistCondition`` to use
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func persistCondition(_ persistCondition: HackleSessionPersistCondition) -> HackleSessionPolicyBuilder {
        self.persistCondition = persistCondition
        return self
    }

    /// Sets the session timeout condition.
    ///
    /// - Parameter timeoutCondition: The ``HackleSessionTimeoutCondition`` to use
    /// - Returns: This builder instance for method chaining
    @discardableResult
    @objc public func timeoutCondition(_ timeoutCondition: HackleSessionTimeoutCondition) -> HackleSessionPolicyBuilder {
        self.timeoutCondition = timeoutCondition
        return self
    }

    /// Builds the ``HackleSessionPolicy`` instance with the specified settings.
    ///
    /// - Returns: A configured ``HackleSessionPolicy`` instance
    @objc public func build() -> HackleSessionPolicy {
        HackleSessionPolicy(
            persistCondition: persistCondition,
            timeoutCondition: timeoutCondition
        )
    }
}
