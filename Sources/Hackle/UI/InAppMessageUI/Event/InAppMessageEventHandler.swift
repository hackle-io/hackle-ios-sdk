//
//  InAppMessageEventHandler.swift
//  Hackle
//
//  Created by yong on 2023/07/18.
//

import Foundation

protocol InAppMessageEventHandler {
    func handle(view: InAppMessageView, event: InAppMessage.Event)
}

class DefaultInAppMessageEventHandler: InAppMessageEventHandler {
    private let clock: Clock
    private let eventTracker: InAppMessageEventTracker
    private let processorFactory: InAppMessageEventProcessorFactory

    init(clock: Clock, eventTracker: InAppMessageEventTracker, processorFactory: InAppMessageEventProcessorFactory) {
        self.clock = clock
        self.eventTracker = eventTracker
        self.processorFactory = processorFactory
    }

    func handle(view: InAppMessageView, event: InAppMessage.Event) {
        let timestamp = clock.now()
        eventTracker.track(context: view.context, event: event, timestamp: timestamp)
        guard let processor = processorFactory.get(event: event) else {
            return
        }
        processor.process(view: view, event: event, timestamp: timestamp)
    }
}
