//
//  InAppMessageEventProcessor.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation


protocol InAppMessageEventProcessor {
    func supports(event: InAppMessage.Event) -> Bool
    func process(view: InAppMessageView, event: InAppMessage.Event, user: HackleUser, timestamp: Date)
}

class InAppMessageEventProcessorFactory {

    private let processors: [InAppMessageEventProcessor]

    init(processors: [InAppMessageEventProcessor]) {
        self.processors = processors
    }

    func get(event: InAppMessage.Event) -> InAppMessageEventProcessor? {
        processors.first { it in
            it.supports(event: event)
        }
    }
}

class InAppMessageImpressionEventProcessor: InAppMessageEventProcessor {

    func supports(event: InAppMessage.Event) -> Bool {
        guard case .impression = event else {
            return false
        }
        return true
    }

    func process(view: InAppMessageView, event: InAppMessage.Event, user: HackleUser, timestamp: Date) {
    }
}

class InAppMessageActionEventProcessor: InAppMessageEventProcessor {

    private let actionHandlerFactory: InAppMessageActionHandlerFactory

    init(actionHandlerFactory: InAppMessageActionHandlerFactory) {
        self.actionHandlerFactory = actionHandlerFactory
    }

    func supports(event: InAppMessage.Event) -> Bool {
        guard case .action = event else {
            return false
        }
        return true
    }

    func process(view: InAppMessageView, event: InAppMessage.Event, user: HackleUser, timestamp: Date) {
        guard case let .action(action, _, _) = event,
              let handler = actionHandlerFactory.get(action: action)
        else {
            return
        }

        handler.handle(view: view, action: action)
    }
}

class InAppMessageCloseEventProcessor: InAppMessageEventProcessor {
    func supports(event: InAppMessage.Event) -> Bool {
        guard case .close = event else {
            return false
        }
        return true
    }

    func process(view: InAppMessageView, event: InAppMessage.Event, user: HackleUser, timestamp: Date) {
        view.dismiss()
    }
}
