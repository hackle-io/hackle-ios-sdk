//
//  HackleNotificationClickAction.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/17/25.
//

import Foundation

/// Types of actions that can be performed when a push notification is clicked.
@objc public enum HackleNotificationClickActionType: Int, RawRepresentable {
    /// Open the application
    case appOpen
    /// Open a link
    case link
    
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "APP_OPEN":
            self = .appOpen
        case "LINK":
            self = .link
        default:
            return nil
        }
    }
    
    public var rawValue: RawValue {
        switch self {
        case .appOpen:
            return "APP_OPEN"
        case .link:
            return "LINK"
        }
    }
}
