//
//  InAppMessageEventProcessor.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation


protocol InAppMessageEventProcessor {
    func supports(event: InAppMessage.Event) -> Bool
    func process(view: InAppMessageView, event: InAppMessage.Event, timestamp: Date)
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

    private static let IMPRESSION_MAX_SIZE = 100

    private let impressionStorage: InAppMessageImpressionStorage

    init(impressionStorage: InAppMessageImpressionStorage) {
        self.impressionStorage = impressionStorage
    }

    func supports(event: InAppMessage.Event) -> Bool {
        guard case .impression = event else {
            return false
        }
        return true
    }

    func process(view: InAppMessageView, event: InAppMessage.Event, timestamp: Date) {
        do {
            try saveImpression(inAppMessage: view.context.inAppMessage, user: view.context.user, timestamp: timestamp)
        } catch {
            Log.error("Failed to process InAppMessageImpressionEvent: \(error)")
        }
    }

    private func saveImpression(inAppMessage: InAppMessage, user: HackleUser, timestamp: Date) throws {
        var impressions = try impressionStorage.get(inAppMessage: inAppMessage)
        let impression = InAppMessageImpression(identifiers: user.identifiers, timestamp: timestamp.timeIntervalSince1970)
        impressions.append(impression)

        if impressions.count > InAppMessageImpressionEventProcessor.IMPRESSION_MAX_SIZE {
            impressions.removeFirst(impressions.count - InAppMessageImpressionEventProcessor.IMPRESSION_MAX_SIZE)
        }

        try impressionStorage.set(inAppMessage: inAppMessage, impressions: impressions)
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

    func process(view: InAppMessageView, event: InAppMessage.Event, timestamp: Date) {
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

    func process(view: InAppMessageView, event: InAppMessage.Event, timestamp: Date) {
        // Do nothing. This method is called after the view is closed.
    }
}
