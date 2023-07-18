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
    private let userManager: UserManager
    private let userResolver: HackleUserResolver
    private let eventTracker: InAppMessageEventTracker
    private let processorFactory: InAppMessageEventProcessorFactory

    init(clock: Clock, userManager: UserManager, userResolver: HackleUserResolver, eventTracker: InAppMessageEventTracker, processorFactory: InAppMessageEventProcessorFactory) {
        self.clock = clock
        self.userManager = userManager
        self.userResolver = userResolver
        self.eventTracker = eventTracker
        self.processorFactory = processorFactory
    }

    func handle(view: InAppMessageView, event: InAppMessage.Event) {
        let timestamp = clock.now()
        let user = userResolver.resolve(user: userManager.currentUser)

        eventTracker.track(context: view.context, event: event, user: user, timestamp: timestamp)

        guard let processor = processorFactory.get(event: event) else {
            return
        }
        processor.process(view: view, event: event, user: user, timestamp: timestamp)
    }
}
