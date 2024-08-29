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
    static let shared = HackleInAppMessageUI()
    
    var eventHandler: InAppMessageEventHandler?
    var window: Window?
    var delegate: HackleInAppMessageDelegate?
    var isRunOnlyCustomAction: Bool = false
    
    var currentMessageView: InAppMessageView? {
        window?.messageViewController?.messageView
    }
    
    private override init() {}
    
    func setup(eventHandler: InAppMessageEventHandler, delegate: HackleInAppMessageDelegate? = nil) {
        self.eventHandler = eventHandler
        self.delegate = delegate
    }

    func present(context: InAppMessagePresentationContext) {
        DispatchQueue.main.async {
            self.presentNow(context: context)
        }
    }

    private func presentNow(context: InAppMessagePresentationContext) {
        guard isMainThread(),
              checkRootViewController(),
              noMessagePresented(),
              orientationSupported(context: context)
        else {
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

    private func orientationSupported(context: InAppMessagePresentationContext) -> Bool {
        context.inAppMessage.supports(orientation: UIUtils.interfaceOrientation)
    }
}
