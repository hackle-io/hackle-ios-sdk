//
//  UserEventPublisher.swift
//  Hackle
//
//  Created by yong on 2023/06/05.
//

import Foundation


protocol UserEventPublisher {
    func addListener(listener: UserEventListener)
    func publish(event: UserEvent)
}

class DefaultUserEventPublisher: UserEventPublisher {

    private var listeners = [UserEventListener]()

    func addListener(listener: UserEventListener) {
        listeners.append(listener)
        Log.debug("UserEventListener added [\(listener.self)]")
    }

    func publish(event: UserEvent) {
        for listener in listeners {
            listener.onEvent(event: event)
        }
    }
}
