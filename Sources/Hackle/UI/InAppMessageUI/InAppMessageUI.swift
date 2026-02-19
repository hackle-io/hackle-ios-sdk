//
//  HackleInAppMessageUI.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation
import UIKit

@objc(HackleInAppMessageUI)
class HackleInAppMessageUI: NSObject, InAppMessagePresenter, @unchecked Sendable {
    let eventHandler: InAppMessageEventHandler
    
    init(eventHandler: InAppMessageEventHandler) {
        self.eventHandler = eventHandler
        super.init()
    }
    
    var window: Window?
    var delegate: HackleInAppMessageDelegate?
    
    var currentMessageView: InAppMessageView? {
        window?.messageViewController?.messageView
    }

    func present(context: InAppMessagePresentationContext) {
        Task { @MainActor in
            self.presentNow(context: context)
        }
    }

    @MainActor private func presentNow(context: InAppMessagePresentationContext) {
        guard checkRootViewController(),
              noMessagePresented(),
              orientationSupported(context: context) else {
            return
        }

        // Message View
        guard let messageView = createMessageView(context: context) else {
            return
        }

        // ViewController
        let viewController = ViewController(
            ui: self,
            context: context,
            messageView: messageView
        )

        // Window
        let window = createWindow(viewController: viewController)
        self.window = window

        // Display
        if #available(iOS 15.0, *) {
            UIView.animate(withDuration: 0.25) {
                window.isHidden = false
            }
        } else {
            window.isHidden = false
        }
    }

    @MainActor private func checkRootViewController() -> Bool {
        UIUtils.keyWindow?.rootViewController != nil
    }

    private func noMessagePresented() -> Bool {
        currentMessageView == nil
    }

    @MainActor private func orientationSupported(context: InAppMessagePresentationContext) -> Bool {
        context.inAppMessage.supports(orientation: UIUtils.interfaceOrientation)
    }
}
