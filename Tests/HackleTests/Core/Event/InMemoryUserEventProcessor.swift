//
//  InMemoryUserEventProcessor.swift
//  HackleTests
//
//  Created by yong on 2023/04/19.
//

import Foundation
@testable import Hackle


class InMemoryUserEventProcessor: UserEventProcessor {

    var processedEvents: [UserEvent] = []

    func process(event: UserEvent) {
        processedEvents.append(event)
    }

    func initialize() {
    }

    func start() {
    }

    func stop() {
    }
}
