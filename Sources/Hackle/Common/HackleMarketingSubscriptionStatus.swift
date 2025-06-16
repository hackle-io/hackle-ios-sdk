//
//  HackleMarketingSubscriptionStatus.swift
//  Hackle
//
//  Created by sungwoo.yeo on 6/16/25.
//

@objc public enum HackleMarketingSubscriptionStatus: Int, RawRepresentable {
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
