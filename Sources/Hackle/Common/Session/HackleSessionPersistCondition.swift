//
//  HackleSessionPersistCondition.swift
//  Hackle
//

import Foundation

@objc public class HackleSessionPersistCondition: NSObject {

    @objc public static let ALWAYS_NEW_SESSION: HackleSessionPersistCondition = AlwaysNewSession()
    @objc public static let NULL_TO_USER_ID: HackleSessionPersistCondition = NullToUserId()

    @objc open func shouldPersist(oldUser: User, newUser: User) -> Bool {
        fatalError("must override shouldPersist")
    }

    private class AlwaysNewSession: HackleSessionPersistCondition {
        override func shouldPersist(oldUser: User, newUser: User) -> Bool { false }
    }

    private class NullToUserId: HackleSessionPersistCondition {
        override func shouldPersist(oldUser: User, newUser: User) -> Bool {
            oldUser.userId == nil && newUser.userId != nil
        }
    }
}
