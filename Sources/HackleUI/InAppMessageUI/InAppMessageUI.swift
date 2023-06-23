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

    private let actionHandlerFactory: ActionHandlerFactory
    private let eventTracker: InAppMessageEventTracker

    init(actionHandlerFactory: ActionHandlerFactory, eventTracker: InAppMessageEventTracker) {
        self.actionHandlerFactory = actionHandlerFactory
        self.eventTracker = eventTracker
        super.init()
    }

    /// The window displaying the current in app message view
    var window: Window?

    /// Thr currently visible message view.
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
              noMessagePresented(),
              orientationSupported(context: context)
        else {
            return
        }

        // - Message View
        guard let messageView = createMessageView(context: context) else {
            Log.error("Failed to create InAppMessageView [\(context.message.layout.displayType)]")
            return
        }

        // - ViewController
        let viewController = ViewController(
            ui: self,
            context: context,
            messageView: messageView
        )

        // - Window
        let window = createWindow(viewController: viewController)
        self.window = window

        // - Display
        if #available(iOS 15.0, *) {
            UIView.animate(withDuration: 0.25) {
                window.isHidden = false
            }
        } else {
            window.isHidden = false
        }
    }

    // MARK: - Present Validation

    private func isMainThread() -> Bool {
        Thread.isMainThread
    }

    private func noMessagePresented() -> Bool {
        currentMessageView == nil
    }

    private func orientationSupported(context: InAppMessageContext) -> Bool {
        context.message.supports(orientation: UIUtils.interfaceOrientation)
    }

    func track(view: InAppMessageView, event: InAppMessage.Event) {
        eventTracker.track(context: view.context, event: event)
    }

    func handleAction(view: InAppMessageView, action: InAppMessage.Action, area: InAppMessage.ActionArea) {
        guard let handler = actionHandlerFactory.get(action: action) else {
            return
        }
        track(view: view, event: .action(action, area))
        handler.handle(view: view, action: action)
    }
}
