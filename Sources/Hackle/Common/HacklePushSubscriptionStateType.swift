//
//  HacklePushSubscriptionStateType.swift
//  Hackle
//
//  Created by hackle on 9/19/24.
//

import Foundation

@objc public enum HacklePushSubscriptionStateType: Int, RawRepresentable {
    case subscribed
    case unsubscribed
    case unknown
    
    public init?(rawValue: String) {
        switch rawValue {
        case "subscribed":
            self = .subscribed
        case "unsubscribed":
            self = .unsubscribed
        case "unknown":
            self = .unknown
        default:
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .subscribed:
            return "subscribed"
        case .unsubscribed:
            return "unsubscribed"
        case .unknown:
            return "unknown"
        }
    }
}
