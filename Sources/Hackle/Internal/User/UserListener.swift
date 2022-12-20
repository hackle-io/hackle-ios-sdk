//
//  UserListener.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation

protocol UserListener {
    func onUserUpdated(user: HackleUser, timestamp: Date)
}
