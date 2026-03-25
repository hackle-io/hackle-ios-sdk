import Foundation

protocol InAppMessageViewEventHandlerFactory {
    func get(handleType: InAppMessageViewEventHandleType) -> InAppMessageViewEventHandler?
}

class DefaultInAppMessageViewEventHandlerFactory: InAppMessageViewEventHandlerFactory {
    private let handlers: [InAppMessageViewEventHandler]

    init(handlers: [InAppMessageViewEventHandler]) {
        self.handlers = handlers
    }

    func get(handleType: InAppMessageViewEventHandleType) -> InAppMessageViewEventHandler? {
        guard let handler = handlers.first(where: { it in it.supports(handleType: handleType) }) else {
            Log.error("Unsupported InAppMessageViewEventHandleType [\(handleType)]")
            return nil
        }
        return handler
    }
}
