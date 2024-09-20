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
        case "SUBSCRIBED":
            self = .subscribed
        case "UNSUBSCRIBED":
            self = .unsubscribed
        case "UNKNOWN":
            self = .unknown
        default:
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .subscribed:
            return "SUBSCRIBED"
        case .unsubscribed:
            return "UNSUBSCRIBED"
        case .unknown:
            return "UNKNOWN"
        }
    }
}
