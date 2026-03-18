import Foundation
import UIKit

/// Base view protocol for InAppMessage
@MainActor
protocol InAppMessageView: UIView, InAppMessageViewAware, HackleInAppMessageView {
    /// The unique identifier of this view.
    nonisolated var id: String { get }

    /// The context in which this InAppMessageView is presented.
    nonisolated var context: InAppMessagePresentationContext { get }

    /// Indicates whether the InAppMessageView is currently presented.
    var presented: Bool { get }

    /// Presents the InAppMessageView on the screen.
    func present()

    /// Dismisses the InAppMessageView from the screen.
    func dismiss()
}

@MainActor
extension InAppMessageView {
    nonisolated var inAppMessage: InAppMessage {
        return context.inAppMessage
    }

    var controller: HackleInAppMessageUI.ViewController? {
        return responders
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

        cleanup()
    }

    func cleanup() {
        guard let controller = controller, let ui = controller.ui else {
            return
        }
        removeFromSuperview()
        ui.window?.windowScene = nil
        ui.window = nil
    }
}

@MainActor
protocol InAppMessageViewAware: UIView {
    var messageView: InAppMessageView? { get }
}

extension InAppMessageViewAware {
    var messageView: InAppMessageView? {
        var current: UIView? = self
        while let view = current {
            if let messageView = view as? InAppMessageView {
                return messageView
            }
            current = view.superview
        }
        return nil
    }

    var clock: Clock {
        return messageView?.controller?.ui?.clock ?? SystemClock.shared
    }

    func handle(event: InAppMessageViewEvent, types: [InAppMessageViewEventHandleType] = [.track, .action]) {
        guard let messageView = messageView,
              let controller = messageView.controller,
              let ui = controller.ui
        else {
            return
        }

        ui.eventProcessor.process(view: messageView, event: event, types: types)
    }

    func handle(event: InAppMessageViewEvent, type: InAppMessageViewEventHandleType) {
        handle(event: event, types: [type])
    }
}

@MainActor
@objc protocol InAppMessageViewLifecycleListener {
    @objc optional func inAppMessageWillPresent()
    @objc optional func inAppMessageDidPresent()
    @objc optional func inAppMessageWillDismiss()
    @objc optional func inAppMessageDidDismiss()
}

@MainActor
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
