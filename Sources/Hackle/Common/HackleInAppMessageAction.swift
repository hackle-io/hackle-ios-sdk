//
//  HackleInAppMessageAction.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc public protocol HackleInAppMessageActionClose {
    var hideDuration: TimeInterval { get }
}

@objc public protocol HackleInAppMessageActionLink {
    var url: String { get }
    var shouldCloseAfterLink: Bool { get }
}

@objc public protocol HackleInAppMessageAction {
    var type: HackleInAppMessageActionType { get }
    var close: HackleInAppMessageActionClose? { get }
    var link: HackleInAppMessageActionLink? { get }
}
