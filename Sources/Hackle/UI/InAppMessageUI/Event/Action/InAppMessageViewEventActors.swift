import Foundation

// MARK: - Impression

class InAppMessageViewImpressionEventActor: InAppMessageViewEventActor {
    func supports(type: InAppMessageViewEventType) -> Bool {
        return type == .impression
    }

    func action(view: InAppMessageView, event: InAppMessageViewEvent) {
        // Do nothing.
    }
}

// MARK: - Action

class InAppMessageViewActionEventActor: InAppMessageViewEventActor {
    private let actionHandlerFactory: InAppMessageActionHandlerFactory

    init(actionHandlerFactory: InAppMessageActionHandlerFactory) {
        self.actionHandlerFactory = actionHandlerFactory
    }

    func supports(type: InAppMessageViewEventType) -> Bool {
        return type == .action
    }

    func action(view: InAppMessageView, event: InAppMessageViewEvent) {
        guard let event = event as? InAppMessageViewActionEvent,
              let handler = actionHandlerFactory.get(action: event.action)
        else {
            return
        }

        if let delegate = view.controller?.ui?.delegate,
           let isProcessed = delegate.onInAppMessageClick?(inAppMessage: view.context.inAppMessage, view: view, action: event.action),
           isProcessed
        {
            return
        }

        /*
            If the view is dismissed within delegate.onInAppMessageClick,
            even if the return value of delegate.onInAppMessageClick is false,
            further execution will stop and not proceed.
            <Note>
            The block below must be executed after the delegate.onInAppMessageClick call
            so that the 'presented' value is updated and works correctly.
         */
        if !view.presented {
            return
        }

        handler.handle(view: view, action: event.action)
    }
}

// MARK: - Close

class InAppMessageViewCloseEventActor: InAppMessageViewEventActor {
    func supports(type: InAppMessageViewEventType) -> Bool {
        return type == .close
    }

    func action(view: InAppMessageView, event: InAppMessageViewEvent) {
        // Do nothing. This method is called after the view is closed.
    }
}
