//
//  InAppMessageListener.swift
//  Hackle
//
//  Created by hackle on 8/28/24.
//

import Foundation

@objc public protocol HackleInAppMessageDelegate {
    /// Called before the InAppMessage is presented.
    @objc optional func onWillOpen(inAppMessage: HackleInAppMessage)

    /// Called after an InAppMessage is presented.
    @objc optional func onDidOpen(inAppMessage: HackleInAppMessage)
    
    /// Called before the InAppMessage is closed.
    @objc optional func onWillClose(inAppMessage: HackleInAppMessage)
    
    /// Called after an InAppMessage is closed.
    @objc optional func onDidClose(inAppMessage: HackleInAppMessage)
    
    /// Called when a clickable element is clicked in an InAppMessage.
    /// - parameter view: The view presenting the InAppMessage
    /// - parameter inAppMessage: The InAppMessage being presented
    /// - parameter action: An action performed by the user by clicking InAppMessage.
    /// - returns: Indicating whether the click action was custom handled. If true, Hackle SDK only track a click event and do nothing else. If false, track click event and handle the click action.
    func onClick(view: HackleInAppMessageView, inAppMessage: HackleInAppMessage, action: HackleInAppMessageAction)
}
