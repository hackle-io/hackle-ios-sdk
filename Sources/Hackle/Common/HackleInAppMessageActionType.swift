//
//  HackleInAppMessageActionType.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc
public enum HackleInAppMessageActionType: Int, RawRepresentable {
    case close
    case hidden
    case link
    case linkAndClose
    
    public typealias RawValue = String
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "CLOSE":
            self = .close
        case "HIDDEN":
            self = .hidden
        case "LINK":
            self = .link
        case "LINK_AND_CLOSE":
            self = .linkAndClose
        default:
            return nil
        }
    }
    
    public var rawValue: RawValue {
        switch self {
        case .close:
            return "CLOSE"
        case .hidden:
            return "HIDDEN"
        case .link:
            return "LINK"
        case .linkAndClose:
            return "LINK_AND_CLOSE"
        }
    }
}
