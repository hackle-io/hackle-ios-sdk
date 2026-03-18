//
//  SessionContext.swift
//  Hackle
//

import Foundation

struct SessionContext: Sendable {
    let oldUser: User
    let newUser: User
    let timestamp: Date
    let isApplicationStateChange: Bool

    static func of(user: User, timestamp: Date, isApplicationStateChange: Bool = false) -> SessionContext {
        SessionContext(
            oldUser: user,
            newUser: user,
            timestamp: timestamp,
            isApplicationStateChange: isApplicationStateChange
        )
    }

    static func of(oldUser: User, newUser: User, timestamp: Date) -> SessionContext {
        SessionContext(
            oldUser: oldUser,
            newUser: newUser,
            timestamp: timestamp,
            isApplicationStateChange: false
        )
    }
}
