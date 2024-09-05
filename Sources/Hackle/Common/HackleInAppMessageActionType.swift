//
//  HackleInAppMessageActionType.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc public enum HackleInAppMessageActionType: Int, RawRepresentable {
    case close
    case link
    
    public init?(rawValue: String) {
        switch rawValue {
        case "CLOSE":
            self = .close
        case "LINK":
            self = .link
        default:
            return nil
        }
    }
    
    public var rawValue: String {
        switch self {
        case .close:
            return "CLOSE"
        case .link:
            return "LINK"
        }
    }
}
