//
//  HackleNotificationClickAction.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/17/25.
//

import Foundation

@objc public enum HackleNotificationClickAction: Int, RawRepresentable {
    case appOpen
    case deepLink
    
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "APP_OPEN":
            self = .appOpen
        case "DEEP_LINK":
            self = .deepLink
        default:
            return nil
        }
    }
    
    public var rawValue: RawValue {
        switch self {
        case .appOpen:
            return "APP_OPEN"
        case .deepLink:
            return "DEEP_LINK"
        }
    }
}
