//
//  InAppMessageActionHandler.swift
//  Hackle
//
//  Created by yong on 2023/06/21.
//

import Foundation

protocol InAppMessageActionHandler {
    func supports(action: InAppMessage.Action) -> Bool
    func handle(view: InAppMessageView, action: InAppMessage.Action)
}

class InAppMessageActionHandlerFactory {
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

class InAppMessageCloseActionHandler: InAppMessageActionHandler {
    func supports(action: InAppMessage.Action) -> Bool {
        action.actionType == .close
    }

    func handle(view: InAppMessageView, action: InAppMessage.Action) {
        view.dismiss()
    }
}

class InAppMessageLinkActionHandler: InAppMessageActionHandler {
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
        urlHandler.open(url: url)
    }
}

class InAppMessageLinkAndCloseHandler: InAppMessageActionHandler {
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
        urlHandler.open(url: url)
    }
}

class InAppMessageHiddenActionHandler: InAppMessageActionHandler {
    private static let DEFAULT_HIDDEN_TIME_INTERVAL = TimeInterval(60 * 60 * 24) // 24H

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
        let expireAt = clock.now() + InAppMessageHiddenActionHandler.DEFAULT_HIDDEN_TIME_INTERVAL
        storage.put(inAppMessage: view.context.inAppMessage, expireAt: expireAt)
        view.dismiss()
    }
}
