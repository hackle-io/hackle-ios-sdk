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

    private let lock = ReadWriteLock(label: "io.hackle.DefaultSessionManager.Lock")
    private var _currentSession: Session? = nil
    private var _lastEventTime: Date? = nil

    var requiredSession: Session {
        currentSession ?? Session.UNKNOWN
    }

    var currentSession: Session? {
        lock.read { _currentSession }
    }

    var lastEventTime: Date? {
        lock.read { _lastEventTime }
    }

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
        lock.write {
            loadSession()
            loadLastEventTime()
        }
        Log.debug("SessionManager initialized.")
    }

    func addListener(listener: SessionListener) {
        self.sessionListeners.append(listener)
        Log.debug("SessionListener added [\(listener)]")
    }

    func startNewSession(oldUser: User, newUser: User, timestamp: Date) -> Session {
        let (ended, started) = lock.write {
            newSession(timestamp: timestamp)
        }
        publish(ended: ended, started: started, oldUser: oldUser, newUser: newUser, timestamp: timestamp)
        return started
    }

    @discardableResult
    func startNewSessionIfNeeded(context: SessionContext) -> Session {
        let transition: (ended: EndedSession?, started: Session)? = lock.write {
            if shouldStartNewSession(context: context) {
                return newSession(timestamp: context.timestamp)
            }
            setLastEventTime(timestamp: context.timestamp)
            return nil
        }
        guard let (ended, started) = transition else {
            return requiredSession
        }
        publish(ended: ended, started: started, oldUser: context.oldUser, newUser: context.newUser, timestamp: context.timestamp)
        return started
    }

    func updateLastEventTime(timestamp: Date) {
        lock.write {
            setLastEventTime(timestamp: timestamp)
        }
    }

    private func setLastEventTime(timestamp: Date) {
        _lastEventTime = timestamp
        keyValueRepository.putDouble(key: DefaultSessionManager.LAST_EVENT_TIME_KEY, value: timestamp.timeIntervalSince1970)
    }

    private func shouldStartNewSession(context: SessionContext) -> Bool {
        if _currentSession == nil {
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
        guard let lastEventTime = _lastEventTime else {
            return true
        }
        return timestamp.timeIntervalSince1970 - lastEventTime.timeIntervalSince1970 >= sessionPolicy.timeoutCondition.timeoutIntervalSeconds
    }

    private typealias EndedSession = (session: Session, lastEventTime: Date)

    private func newSession(timestamp: Date) -> (ended: EndedSession?, started: Session) {
        let ended = endedSession()

        let newSession = Session.create(timestamp: timestamp)
        _currentSession = newSession
        saveSession(session: newSession)
        setLastEventTime(timestamp: timestamp)

        return (ended, newSession)
    }

    private func endedSession() -> EndedSession? {
        guard let oldSession = _currentSession, let lastEventTime = _lastEventTime else {
            return nil
        }
        return (oldSession, lastEventTime)
    }

    private func publish(ended: EndedSession?, started: Session, oldUser: User, newUser: User, timestamp: Date) {
        if let ended = ended {
            Log.debug("SessionManager.publishEnd(session: \(ended.session.id))")
            for listener in sessionListeners {
                listener.onSessionEnded(session: ended.session, user: oldUser, timestamp: ended.lastEventTime)
            }
        }

        Log.debug("SessionManager.publishStart(session: \(started.id))")
        for listener in sessionListeners {
            listener.onSessionStarted(session: started, user: newUser, timestamp: timestamp)
        }
    }

    private func saveSession(session: Session) {
        keyValueRepository.putString(key: DefaultSessionManager.SESSION_ID_KEY, value: session.id)
    }

    private func loadSession() {
        if let sessionId = keyValueRepository.getString(key: DefaultSessionManager.SESSION_ID_KEY) {
            _currentSession = Session(id: sessionId)
        }
        Log.debug("Session loaded [\(_currentSession?.id ?? "nil")]")
    }

    private func loadLastEventTime() {
        let lastEventTime = keyValueRepository.getDouble(key: DefaultSessionManager.LAST_EVENT_TIME_KEY)
        if lastEventTime > 0 {
            self._lastEventTime = Date(timeIntervalSince1970: lastEventTime)
        }
        Log.debug("LastEventTime loaded [\(lastEventTime)]")
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        startNewSessionIfNeeded(context: SessionContext.of(oldUser: oldUser, newUser: newUser, timestamp: timestamp))
    }

    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {
        // nothing to do
    }
}

extension DefaultSessionManager: ApplicationLifecycleListener {
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        Log.debug("SessionManager.onForeground")
        startNewSessionIfNeeded(context: SessionContext.of(user: userManager.currentUser, timestamp: timestamp, isApplicationStateChange: true))
    }

    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        Log.debug("SessionManager.onBackground")
        lock.write {
            setLastEventTime(timestamp: timestamp)
            guard let session = _currentSession else {
                return
            }
            saveSession(session: session)
        }
    }
}
