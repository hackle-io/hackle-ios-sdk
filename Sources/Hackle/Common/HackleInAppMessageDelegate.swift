//
//  InAppMessageListener.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

/// Delegate protocol for handling in-app message events.
@objc public protocol HackleInAppMessageDelegate {
    /// Called before the InAppMessage is presented.
    ///
    /// - Parameter inAppMessage: the ``HackleInAppMessage`` that will appear
    @objc(inAppMessageWillAppear:)
    optional func inAppMessageWillAppear(inAppMessage: HackleInAppMessage)
    
    /// Called after an InAppMessage is presented.
    ///
    /// - Parameter inAppMessage: the ``HackleInAppMessage`` that appeared
    @objc(inAppMessageDidAppear:)
    optional func inAppMessageDidAppear(inAppMessage: HackleInAppMessage)
    
    /// Called before the InAppMessage is closed.
    ///
    /// - Parameter inAppMessage: the ``HackleInAppMessage`` that will disappear
    @objc(inAppMessageWillDisappear:)
    optional func inAppMessageWillDisappear(inAppMessage: HackleInAppMessage)
    
    /// Called after an InAppMessage is closed.
    ///
    /// - Parameter inAppMessage: the ``HackleInAppMessage`` that disappeared
    @objc(inAppMessageDidDisappear:)
    optional func inAppMessageDidDisappear(inAppMessage: HackleInAppMessage)
    
    /// Called when a clickable element is clicked in an InAppMessage.
    ///
    /// - Parameters:
    ///   - inAppMessage: the ``HackleInAppMessage`` being presented
    ///   - view: the ``HackleInAppMessageView`` presenting the InAppMessage
    ///   - action: an ``HackleInAppMessageAction`` performed by the user
    /// - Returns: indicating whether the click action was custom handled. If true, Hackle SDK only tracks a click event and does nothing else. If false, tracks click event and handles the click action.
    @objc(onInAppMessageClickWith:view:action:)
    optional func onInAppMessageClick(inAppMessage: HackleInAppMessage, view: HackleInAppMessageView, action: HackleInAppMessageAction) -> Bool
}
