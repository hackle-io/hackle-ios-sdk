//
//  InAppMessageListener.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc public protocol HackleInAppMessageDelegate {
    /// Called before the InAppMessage is presented.
    @objc(inAppMessageWillAppear:)
    optional func inAppMessageWillAppear(inAppMessage: HackleInAppMessage)
    
    /// Called after an InAppMessage is presented.
    @objc(inAppMessageDidAppear:)
    optional func inAppMessageDidAppear(inAppMessage: HackleInAppMessage)
    
    /// Called before the InAppMessage is closed.
    @objc(inAppMessageWillDisappear:)
    optional func inAppMessageWillDisappear(inAppMessage: HackleInAppMessage)
    
    /// Called after an InAppMessage is closed.
    @objc(inAppMessageDidDisappear:)
    optional func inAppMessageDidDisappear(inAppMessage: HackleInAppMessage)
    
    /**
     Called when a clickable element is clicked in an InAppMessage.
     - parameter inAppMessage: The InAppMessage being presented
     - parameter view: The view presenting the InAppMessage
     - parameter action: An action performed by the user by clicking InAppMessage.
     - returns: Indicating whether the click action was custom handled. If true, Hackle SDK only track a click event and do nothing else. If false, track click event and handle the click action.
     */
    @objc(onInAppMessageClickWith:view:action:)
    optional func onInAppMessageClick(inAppMessage: HackleInAppMessage, view: HackleInAppMessageView, action: HackleInAppMessageAction) -> Bool
}
