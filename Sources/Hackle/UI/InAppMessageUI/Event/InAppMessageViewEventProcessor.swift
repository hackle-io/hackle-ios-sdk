import Foundation

protocol InAppMessageViewEventProcessor {
    @MainActor func process(view: InAppMessageView, event: InAppMessageViewEvent, types: [InAppMessageViewEventHandleType])
}

class DefaultInAppMessageViewEventProcessor: InAppMessageViewEventProcessor {
    private let handlerFactory: InAppMessageViewEventHandlerFactory
    init(handlerFactory: InAppMessageViewEventHandlerFactory) {
        self.handlerFactory = handlerFactory
    }

    func process(view: InAppMessageView, event: InAppMessageViewEvent, types: [InAppMessageViewEventHandleType]) {
        Log.debug("InAppMessageViewEvent process. dispatchId: \(view.context.dispatchId), inAppMessageKey: \(view.context.inAppMessage.key), event: \(event.type)")
        for handleType in types {
            guard let handler = handlerFactory.get(handleType: handleType) else {
                continue
            }
            handler.handle(view: view, event: event)
        }
    }
}
