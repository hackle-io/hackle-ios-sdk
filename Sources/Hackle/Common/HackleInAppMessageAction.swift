//
//  HackleInAppMessageAction.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc public class HackleInAppMessageActionClose: NSObject {
    @objc public let hideDurationMills: TimeInterval
    
    init(hideDurationMills: TimeInterval) {
        self.hideDurationMills = hideDurationMills
    }
}

@objc public class HackleInAppMessageActionLink: NSObject {
    @objc public let url: String
    @objc public let shouldCloseAfterLink: Bool
    
    init(url: String, shouldCloseAfterLink: Bool) {
        self.url = url
        self.shouldCloseAfterLink = shouldCloseAfterLink
    }
}

@objc public protocol HackleInAppMessageAction {
    var type: HackleInAppMessageActionType { get }
    var close: HackleInAppMessageActionClose? { get }
    var link: HackleInAppMessageActionLink? { get }
}
