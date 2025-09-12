//
//  HackleNotification.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/17/25.
//

import Foundation

/// Protocol representing a Hackle push notification.
@objc public protocol HackleNotification {
    /// The type of action to be performed when the notification is clicked.
    var actionType: HackleNotificationClickActionType { get }
    /// The link URL if the action type is link, nil otherwise.
    var link: String? { get }
}
