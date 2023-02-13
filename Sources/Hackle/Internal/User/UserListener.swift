//
//  UserListener.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation

protocol UserListener {
    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date)
}
