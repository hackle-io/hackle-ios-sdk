//
//  HackleInAppMessageUI.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation
import UIKit

@objc(HackleInAppMessageUI)
class HackleInAppMessageUI: NSObject, InAppMessagePresenter {

    let eventHandler: InAppMessageEventHandler

    init(eventHandler: InAppMessageEventHandler) {
        self.eventHandler = eventHandler
        super.init()
    }

    var window: Window?

    var currentMessageView: InAppMessageView? {
        window?.messageViewController?.messageView
    }

    func present(context: InAppMessageContext) {
        DispatchQueue.main.async {
            self.presentNow(context: context)
        }
    }

    private func presentNow(context: InAppMessageContext) {
        guard isMainThread(),
              checkRootViewController(),
              noMessagePresented(),
              orientationSupported(context: context)
        else {
            return
        }

        // Message View
        guard let messageView = createMessageView(context: context) else {
            Log.error("Failed to create InAppMessageView [\(context.message.layout.displayType)]")
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

    // Present Validation

    private func isMainThread() -> Bool {
        Thread.isMainThread
    }

    private func checkRootViewController() -> Bool {
        UIUtils.keyWindow?.rootViewController != nil
    }

    private func noMessagePresented() -> Bool {
        currentMessageView == nil
    }

    private func orientationSupported(context: InAppMessageContext) -> Bool {
        context.inAppMessage.supports(orientation: UIUtils.interfaceOrientation)
    }
}
