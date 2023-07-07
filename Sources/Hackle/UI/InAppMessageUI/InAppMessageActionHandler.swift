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


extension HackleInAppMessageUI {

    class ActionHandlerFactory {

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

    class CloseActionHandler: InAppMessageActionHandler {
        func supports(action: InAppMessage.Action) -> Bool {
            action.type == .close
        }

        func handle(view: InAppMessageView, action: InAppMessage.Action) {
            view.dismiss()
        }
    }

    class LinkActionHandler: InAppMessageActionHandler {
        func supports(action: InAppMessage.Action) -> Bool {
            action.type == .webLink
        }

        func handle(view: InAppMessageView, action: InAppMessage.Action) {
            guard let value = action.value,
                  let url = URL(string: value)
            else {
                Log.error("Invalid url: \(action.value.orNil)")
                return
            }
            UIUtils.application.open(url)
        }
    }

    class HiddenActionHandler: InAppMessageActionHandler {

        private static let DEFAULT_HIDDEN_TIME_INTERVAL = TimeInterval(60 * 60 * 24) // 24H

        private let storage: InAppMessageHiddenStorage

        init(storage: InAppMessageHiddenStorage) {
            self.storage = storage
        }

        func supports(action: InAppMessage.Action) -> Bool {
            action.type == .hidden
        }

        func handle(view: InAppMessageView, action: InAppMessage.Action) {
            let expireAt = Date(timeIntervalSinceNow: HiddenActionHandler.DEFAULT_HIDDEN_TIME_INTERVAL)
            storage.put(inAppMessage: view.context.inAppMessage, expireAt: expireAt)
            view.dismiss()
        }
    }
}
