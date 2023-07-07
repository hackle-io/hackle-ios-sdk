//
//  UserEventPublisherStub.swift
//  HackleTests
//
//  Created by yong on 2023/06/27.
//

import Foundation
@testable import Hackle


class UserEventPublisherStub: UserEventPublisher {

    var events = [UserEvent]()


    func addListener(listener: UserEventListener) {

    }

    func publish(event: UserEvent) {
        events.append(event)
    }
}