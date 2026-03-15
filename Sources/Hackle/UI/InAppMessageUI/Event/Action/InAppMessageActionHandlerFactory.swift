import Foundation

protocol InAppMessageActionHandlerFactory {
    func get(action: InAppMessage.Action) -> InAppMessageActionHandler?
}

class DefaultInAppMessageActionHandlerFactory: InAppMessageActionHandlerFactory {
    private let handlers: [InAppMessageActionHandler]

    init(handlers: [InAppMessageActionHandler]) {
        self.handlers = handlers
    }

    func get(action: InAppMessage.Action) -> InAppMessageActionHandler? {
        handlers.first {
            $0.supports(action: action)
        }
    }
}
