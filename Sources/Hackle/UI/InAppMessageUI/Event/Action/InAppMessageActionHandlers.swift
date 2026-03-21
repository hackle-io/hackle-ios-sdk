import Foundation

class InAppMessageCloseActionHandler: InAppMessageActionHandler {
    func supports(action: InAppMessage.Action) -> Bool {
        action.actionType == .close
    }

    func handle(view: InAppMessageView, action: InAppMessage.Action) {
        view.dismiss()
    }
}

final class InAppMessageLinkActionHandler: InAppMessageActionHandler, Sendable {
    private let urlHandler: UrlHandler

    init(urlHandler: UrlHandler) {
        self.urlHandler = urlHandler
    }

    func supports(action: InAppMessage.Action) -> Bool {
        action.actionType == .webLink
    }

    func handle(view: InAppMessageView, action: InAppMessage.Action) {
        guard let value = action.value, let url = URL(string: value) else {
            Log.error("Invalid url: \(action.value.orNil)")
            return
        }
        Task { @MainActor in
            urlHandler.open(url: url)
        }
    }
}

final class InAppMessageLinkAndCloseHandler: InAppMessageActionHandler, Sendable {
    private let urlHandler: UrlHandler

    init(urlHandler: UrlHandler) {
        self.urlHandler = urlHandler
    }

    func supports(action: InAppMessage.Action) -> Bool {
        action.actionType == .linkAndClose
    }

    func handle(view: InAppMessageView, action: InAppMessage.Action) {
        guard let value = action.value, let url = URL(string: value) else {
            Log.error("Invalid url: \(action.value.orNil)")
            return
        }
        view.dismiss()
        Task { @MainActor in
            urlHandler.open(url: url)
        }
    }
}

class InAppMessageHiddenActionHandler: InAppMessageActionHandler {
    private let clock: Clock
    private let storage: InAppMessageHiddenStorage

    init(clock: Clock, storage: InAppMessageHiddenStorage) {
        self.clock = clock
        self.storage = storage
    }

    func supports(action: InAppMessage.Action) -> Bool {
        action.actionType == .hidden
    }

    func handle(view: InAppMessageView, action: InAppMessage.Action) {
        if view.context.decisionReason == DecisionReason.OVERRIDDEN {
            view.dismiss()
            return
        }

        let expireAt = clock.now() + action.hiddenTimeInterval
        storage.put(inAppMessage: view.context.inAppMessage, expireAt: expireAt)
        view.dismiss()
    }
}
