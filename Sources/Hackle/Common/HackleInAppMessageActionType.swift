//
//  HackleInAppMessageActionType.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

/// Types of actions that can be performed on in-app messages.
@objc public enum HackleInAppMessageActionType: Int, RawRepresentable {
    /// Close the in-app message
    case close
    /// Open a link
    case link
    
    public typealias RawValue = String
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "CLOSE":
            self = .close
        case "LINK":
            self = .link
        default:
            return nil
        }
    }
    
    public var rawValue: RawValue {
        switch self {
        case .close:
            return "CLOSE"
        case .link:
            return "LINK"
        }
    }
}
