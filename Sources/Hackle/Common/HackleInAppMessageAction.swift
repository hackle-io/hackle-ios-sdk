//
//  HackleInAppMessageAction.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

/// Protocol for close action properties in an in-app message.
@objc public protocol HackleInAppMessageActionClose {
    /// Duration to hide the in-app message after close action.
    var hideDuration: TimeInterval { get }
}

/// Protocol for link action properties in an in-app message.
@objc public protocol HackleInAppMessageActionLink {
    /// URL to open when link action is triggered.
    var url: String { get }
    /// Whether to close the in-app message after opening the link.
    var shouldCloseAfterLink: Bool { get }
}

/// Protocol representing an action that can be performed on an in-app message.
@objc public protocol HackleInAppMessageAction {
    /// The type of action.
    var type: HackleInAppMessageActionType { get }
    /// Close action properties, if applicable.
    var close: HackleInAppMessageActionClose? { get }
    /// Link action properties, if applicable.
    var link: HackleInAppMessageActionLink? { get }
}
