//
//  SessionManager.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation
import UIKit


protocol SessionManager {

    var requiredSession: Session { get }

    var currentSession: Session? { get }

    var lastEventTime: Date? { get }

    func initialize()

    @discardableResult
    func startNewSession(oldUser: User, newUser: User, timestamp: Date) -> Session

    @discardableResult
    func startNewSessionIfNeeded(context: SessionContext) -> Session

    func updateLastEventTime(timestamp: Date)
}

class DefaultSessionManager: SessionManager, UserListener {

    private let userManager: UserManager
    private let keyValueRepository: KeyValueRepository
    private let applicationLifecycleManager: ApplicationLifecycleManager
    private let sessionPolicy: HackleSessionPolicy
    private var sessionListeners: [SessionListener]

    var requiredSession: Session {
        currentSession ?? Session.UNKNOWN
    }

    private(set) var currentSession: Session? = nil
    private(set) var lastEventTime: Date? = nil

    init(
        userManager: UserManager,
        keyValueRepository: KeyValueRepository,
        applicationLifecycleManager: ApplicationLifecycleManager,
        sessionPolicy: HackleSessionPolicy
    ) {
        self.userManager = userManager
        self.keyValueRepository = keyValueRepository
        self.applicationLifecycleManager = applicationLifecycleManager
        self.sessionPolicy = sessionPolicy
        self.sessionListeners = []
    }

    private static let SESSION_ID_KEY = "session_id"
    private static let LAST_EVENT_TIME_KEY = "last_event_time"

    func initialize() {
        loadSession()
        loadLastEventTime()
        Log.debug("SessionManager initialized.")
    }

    func addListener(listener: SessionListener) {
        self.sessionListeners.append(listener)
        Log.debug("SessionListener added [\(listener)]")
    }

    func startNewSession(oldUser: User, newUser: User, timestamp: Date) -> Session {
        endSession(user: oldUser)
        return newSession(user: newUser, timestamp: timestamp)
    }

    @discardableResult
    func startNewSessionIfNeeded(context: SessionContext) -> Session {
        if shouldStartNewSession(context: context) {
            return startNewSession(oldUser: context.oldUser, newUser: context.newUser, timestamp: context.timestamp)
        }

        updateLastEventTime(timestamp: context.timestamp)
        return requiredSession
    }

    func updateLastEventTime(timestamp: Date) {
        lastEventTime = timestamp
        keyValueRepository.putDouble(key: DefaultSessionManager.LAST_EVENT_TIME_KEY, value: timestamp.timeIntervalSince1970)
    }

    private func shouldStartNewSession(context: SessionContext) -> Bool {
        if currentSession == nil {
            return true
        }

        if !context.oldUser.identifierEquals(other: context.newUser) {
            if !sessionPolicy.persistCondition.shouldPersist(oldUser: context.oldUser, newUser: context.newUser) {
                return true
            }
        }

        return isTimeoutEnabled(context: context) && isSessionTimedOut(timestamp: context.timestamp)
    }

    private func isTimeoutEnabled(context: SessionContext) -> Bool {
        let timeoutCondition = sessionPolicy.timeoutCondition
        if context.isApplicationStateChange {
            return timeoutCondition.onApplicationStateChange
        }
        if applicationLifecycleManager.currentState == .background {
            return timeoutCondition.onBackground
        }
        return timeoutCondition.onForeground
    }

    private func isSessionTimedOut(timestamp: Date) -> Bool {
        guard let lastEventTime = lastEventTime else {
            return true
        }
        return timestamp.timeIntervalSince1970 - lastEventTime.timeIntervalSince1970 >= sessionPolicy.timeoutCondition.timeoutIntervalSeconds
    }

    private func endSession(user: User) {
        guard let oldSession = currentSession, let lastEventTime = lastEventTime else {
            return
        }

        Log.debug("SessionManager.publishEnd(session: \(oldSession.id))")
        for listener in sessionListeners {
            listener.onSessionEnded(session: oldSession, user: user, timestamp: lastEventTime)
        }
    }

    @discardableResult
    private func newSession(user: User, timestamp: Date) -> Session {
        let newSession = Session.create(timestamp: timestamp)
        currentSession = newSession
        saveSession(session: newSession)

        updateLastEventTime(timestamp: timestamp)

        Log.debug("SessionManager.publishStart(session: \(newSession.id))")
        for listener in sessionListeners {
            listener.onSessionStarted(session: newSession, user: user, timestamp: timestamp)
        }
        return newSession
    }

    private func saveSession(session: Session) {
        keyValueRepository.putString(key: DefaultSessionManager.SESSION_ID_KEY, value: session.id)
    }

    private func loadSession() {
        if let sessionId = keyValueRepository.getString(key: DefaultSessionManager.SESSION_ID_KEY) {
            currentSession = Session(id: sessionId)
        }
        Log.debug("Session loaded [\(currentSession?.id ?? "nil")]")
    }

    private func loadLastEventTime() {
        let lastEventTime = keyValueRepository.getDouble(key: DefaultSessionManager.LAST_EVENT_TIME_KEY)
        if lastEventTime > 0 {
            self.lastEventTime = Date(timeIntervalSince1970: lastEventTime)
        }
        Log.debug("LastEventTime loaded [\(lastEventTime)]")
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        startNewSessionIfNeeded(context: SessionContext.of(oldUser: oldUser, newUser: newUser, timestamp: timestamp))
    }
}

extension DefaultSessionManager: ApplicationLifecycleListener {
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        Log.debug("SessionManager.onForeground")
        startNewSessionIfNeeded(context: SessionContext.of(user: userManager.currentUser, timestamp: timestamp, isApplicationStateChange: true))
    }

    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        Log.debug("SessionManager.onBackground")
        updateLastEventTime(timestamp: timestamp)
        guard let session = currentSession else {
            return
        }
        saveSession(session: session)
    }
}
