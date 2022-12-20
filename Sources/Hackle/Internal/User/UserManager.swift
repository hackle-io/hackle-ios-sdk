//
//  UserManager.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation


protocol UserManager {

    func updateUser(user: HackleUser)
}

class DefaultUserManager: UserManager {

    private var userListeners = [UserListener]()
    private var currentUser: HackleUser? = nil

    func addListener(listener: UserListener) {
        userListeners.append(listener)
    }

    func updateUser(user: HackleUser) {
        if isUserChanged(nextUser: user) {
            changeUser(user: user, timestamp: Date())
        }
        currentUser = user
    }

    private func isUserChanged(nextUser: HackleUser) -> Bool {
        guard let currentUser = currentUser else {
            return false
        }
        return !currentUser.isSameUser(next: nextUser)
    }

    private func changeUser(user: HackleUser, timestamp: Date) {
        for listener in userListeners {
            listener.onUserUpdated(user: user, timestamp: timestamp)
        }
    }
}

private extension HackleUser {
    func isSameUser(next: HackleUser) -> Bool {
        if self.userId != nil && next.userId != nil {
            return self.userId == next.userId
        } else {
            return self.deviceId == next.deviceId
        }
    }
}