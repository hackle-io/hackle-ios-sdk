//
//  UserListener.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation

protocol UserListener {
    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date)

    // for $properties (only Local)
    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date)
}

