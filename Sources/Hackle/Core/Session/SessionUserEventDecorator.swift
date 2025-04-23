//
//  SessionUserEventDecorator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 4/22/25.
//

import Foundation

class SessionUserEventDecorator: UserEventDecorator {
    private let sessionManager: SessionManager

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    func decorate(event: UserEvent) -> UserEvent {
        if event.user.sessionId != nil {
            return event
        }

        guard let session = sessionManager.currentSession else {
            return event
        }

        let decoratedUser = event.user.toBuilder()
            .identifier(.session, session.id, overwrite: false)
            .build()
        return event.with(user: decoratedUser)
    }
}
