import Foundation
import UIKit

/// Base view protocol for InAppMessage
protocol InAppMessageView: UIView, HackleInAppMessageView {

    /// Indicates whether the InAppMessageView is currently presented.
    var presented: Bool { get }

    /// The context in which this InAppMessageView is presented.
    var context: InAppMessagePresentationContext { get }

    /// Presents the InAppMessageView on the screen.
    func present()

    /// Dismisses the InAppMessageView from the screen.
    func dismiss()
}

extension InAppMessageView {

    var controller: HackleInAppMessageUI.ViewController? {
        responders
            .lazy
            .compactMap {
                $0 as? HackleInAppMessageUI.ViewController
            }
            .first
    }

    private func publish(lifecycle: InAppMessageLifecycle) {
        publishInAppMessageLifecycle(lifecycle: lifecycle)
    }

    func willPresent() {
        guard let controller = controller, let ui = controller.ui else {
            return
        }
        publish(lifecycle: .willPresent)
        ui.delegate?.inAppMessageWillAppear?(inAppMessage: context.inAppMessage)
    }

    func didPresent() {
        guard let controller = controller, let ui = controller.ui else {
            return
        }
        publish(lifecycle: .didPresent)
        ui.delegate?.inAppMessageDidAppear?(inAppMessage: context.inAppMessage)
    }

    func willDismiss() {
        guard let controller = controller, let ui = controller.ui else {
            return
        }
        publish(lifecycle: .willDismiss)
        ui.delegate?.inAppMessageWillDisappear?(inAppMessage: context.inAppMessage)
    }

    func didDismiss() {
        guard let controller = controller, let ui = controller.ui else {
            return
        }
        publish(lifecycle: .didDismiss)
        ui.delegate?.inAppMessageDidDisappear?(inAppMessage: context.inAppMessage)

        removeFromSuperview()
        if #available(iOS 13.0, *) {
            ui.window?.windowScene = nil
        }
        ui.window = nil
    }

    func handle(event: InAppMessage.Event) {
        guard let controller = controller, let ui = controller.ui else {
            return
        }
        ui.eventHandler.handle(view: self, event: event)
    }
}

@objc protocol InAppMessageViewLifecycleListener {
    @objc optional func inAppMessageWillPresent()
    @objc optional func inAppMessageDidPresent()
    @objc optional func inAppMessageWillDismiss()
    @objc optional func inAppMessageDidDismiss()
}

private extension InAppMessageViewLifecycleListener {
    func onLifecycle(lifecycle: InAppMessageLifecycle) {
        switch lifecycle {
        case .willPresent:
            inAppMessageWillPresent?()
        case .didPresent:
            inAppMessageDidPresent?()
        case .willDismiss:
            inAppMessageWillDismiss?()
        case .didDismiss:
            inAppMessageDidDismiss?()
        }
    }
}

private extension UIView {
    func publishInAppMessageLifecycle(lifecycle: InAppMessageLifecycle) {
        if let listener = self as? InAppMessageViewLifecycleListener {
            listener.onLifecycle(lifecycle: lifecycle)
        }
        for subview in subviews {
            subview.publishInAppMessageLifecycle(lifecycle: lifecycle)
        }
    }
}
