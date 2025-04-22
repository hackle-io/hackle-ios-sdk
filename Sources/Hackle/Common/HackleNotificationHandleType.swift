//
//  HandleHackleAction.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/22/25.
//

import Foundation

/// Hackle Push Notification Action 처리 여부
@objc public enum HackleNotificationHandleType: Int, RawRepresentable {
    /// Hackle Push Notification Action 처리
    case process
    /// push click event 만 처리
    case pushClickOnly
}
