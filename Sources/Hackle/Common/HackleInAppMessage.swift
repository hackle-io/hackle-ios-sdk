//
//  HackleInAppMessage.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

/// Represents an in-app message in the Hackle system.
@objc public protocol HackleInAppMessage {
    /// The unique key identifying this in-app message.
    var key: Int64 { get }
}
