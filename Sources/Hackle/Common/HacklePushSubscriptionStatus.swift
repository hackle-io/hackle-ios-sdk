//
//  HacklePushSubscriptionStatus.swift
//  Hackle
//
//  Created by hackle on 9/19/24.
//

import Foundation

@available(*, deprecated, message: "Use HackleSubscriptionStatus instead.")
@objc public enum HacklePushSubscriptionStatus: Int, RawRepresentable {
    case subscribed
    case unsubscribed
    case unknown
    
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
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
    
    public var rawValue: RawValue {
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
