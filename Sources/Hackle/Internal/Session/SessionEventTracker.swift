//
//  SessionEventTracker.swift
//  Hackle
//
//  Created by yong on 2023/02/02.
//

import Foundation

class SessionEventTracker: SessionListener {

    private let hackleUserResolver: HackleUserResolver
    private let core: HackleCore

    init(hackleUserResolver: HackleUserResolver, core: HackleCore) {
        self.hackleUserResolver = hackleUserResolver
        self.core = core
    }

    func onSessionStarted(session: Session, user: User, timestamp: Date) {
        track(eventKey: SessionEventTracker.SESSION_START_EVENT_NAME, session: session, user: user, timestamp: timestamp)
    }

    func onSessionEnded(session: Session, user: User, timestamp: Date) {
        track(eventKey: SessionEventTracker.SESSION_END_EVENT_NAME, session: session, user: user, timestamp: timestamp)
    }

    private func track(eventKey: String, session: Session, user: User, timestamp: Date) {
        let event = Event(key: eventKey, properties: ["sessionId": session.id])

        let hackleUser = hackleUserResolver.resolve(user: user)
            .toBuilder()
            .identifier(.session, session.id, overwrite: false)
            .build()

        core.track(event: event, user: hackleUser, timestamp: timestamp)
        Log.debug("\(eventKey) event tracked [\(session.id)]")
    }
}


extension SessionEventTracker {

    private static let SESSION_START_EVENT_NAME = "$session_start"
    private static let SESSION_END_EVENT_NAME = "$session_end"

    static func isSessionEvent(event: UserEvent) -> Bool {
        guard let trackEvent = event as? UserEvents.Track else {
            return false
        }
        return trackEvent.event.key == SessionEventTracker.SESSION_START_EVENT_NAME || trackEvent.event.key == SessionEventTracker.SESSION_END_EVENT_NAME
    }
}
