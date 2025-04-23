//
//  HackleNotification.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/17/25.
//

import Foundation

@objc public protocol HackleNotification {
    var actionType: HackleNotificationClickActionType { get }
    var link: String? { get }
}
