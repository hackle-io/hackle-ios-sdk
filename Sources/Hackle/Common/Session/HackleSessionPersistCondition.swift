//
//  HackleSessionPersistCondition.swift
//  Hackle
//

import Foundation

/// Determines whether an existing session should be persisted when the user identity changes.
@objc open class HackleSessionPersistCondition: NSObject, @unchecked Sendable {

    /// Always starts a new session when the user identity changes.
    ///
    /// This is the default persist condition.
    @objc public static let ALWAYS_NEW_SESSION: HackleSessionPersistCondition = AlwaysNewSession()

    /// Persists the current session when transitioning from an anonymous user to an identified user.
    ///
    /// The session is preserved only when the old user has no userId (`nil`) and the new user has a userId.
    /// In all other identity change cases, a new session is started.
    @objc public static let NULL_TO_USER_ID: HackleSessionPersistCondition = NullToUserId()

    /// Returns whether the current session should be persisted when the user changes.
    ///
    /// Subclasses must override this method to provide custom persist logic.
    ///
    /// - Parameters:
    ///   - oldUser: The previous user before the identity change
    ///   - newUser: The new user after the identity change
    /// - Returns: `true` if the current session should be persisted, `false` to start a new session
    /// - Important: Subclass implementations must be thread-safe to preserve `Sendable` guarantees.
    @objc open func shouldPersist(oldUser: User, newUser: User) -> Bool {
        Log.error("HackleSessionPersistCondition.shouldPersist must be overridden")
        return false
    }

    private final class AlwaysNewSession: HackleSessionPersistCondition, @unchecked Sendable {
        override func shouldPersist(oldUser: User, newUser: User) -> Bool { false }
    }

    private final class NullToUserId: HackleSessionPersistCondition, @unchecked Sendable {
        override func shouldPersist(oldUser: User, newUser: User) -> Bool {
            oldUser.userId == nil && newUser.userId != nil
        }
    }
}
