//
//  HackleInAppMessageAction.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc public protocol HackleInAppMessageAction {
    var type: HackleInAppMessageActionType { get }
    var url: String? { get }
}
