//
//  SessionUserEventDecorator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/22/25.
//

import Foundation

class SessionUserEventDecorator: UserEventDecorator {
    private let userDecorator: SessionUserDecorator

    init(userDecorator: SessionUserDecorator) {
        self.userDecorator = userDecorator
    }
    
    func decorate(event: UserEvent) -> UserEvent {
        let decoratedUser = userDecorator.decorate(user: event.user)
        return event.with(user: decoratedUser)
    }
}
