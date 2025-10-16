//
//  SessionUserDecorator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 10/14/25.
//

class SessionUserDecorator: UserDecorator {

    private let sessionManager: SessionManager
    
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }
    
    func decorate(user: HackleUser) -> HackleUser {
        if user.sessionId != nil {
            return user
        }

        guard let session = sessionManager.currentSession else {
            return user
        }

        let decoratedUser = user.toBuilder()
            .identifier(.session, session.id, overwrite: false)
            .build()
        return decoratedUser
    }
}
