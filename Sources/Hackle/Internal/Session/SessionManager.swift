//
//  SessionManager.swift
//  Hackle
//
//  Created by yong on 2022/12/16.
//

import Foundation


protocol SessionManager {

    var requiredSession: Session { get }

    var currentSession: Session? { get }

    var lastEventTime: Date? { get }

    func initialize()

    func startNewSession(user: User, timestamp: Date) -> Session

    func startNewSessionIfNeeded(user: User, timestamp: Date) -> Session

    func updateLastEventTime(timestamp: Date)
}

class DefaultSessionManager: SessionManager, AppStateChangeListener, UserListener {

    private let userManager: UserManager
    private let keyValueRepository: KeyValueRepository
    private let sessionTimeout: TimeInterval
    private var sessionListeners: [SessionListener]

    var requiredSession: Session {
        currentSession ?? Session.UNKNOWN
    }

    private(set) var currentSession: Session? = nil
    private(set) var lastEventTime: Date? = nil

    init(userManager: UserManager, keyValueRepository: KeyValueRepository, sessionTimeout: TimeInterval) {
        self.userManager = userManager
        self.keyValueRepository = keyValueRepository
        self.sessionTimeout = sessionTimeout
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

    func startNewSession(user: User, timestamp: Date) -> Session {
        endSession(user: user)
        return newSession(user: user, timestamp: timestamp)
    }

    @discardableResult
    func startNewSessionIfNeeded(user: User, timestamp: Date) -> Session {
        guard let lastEventTime = lastEventTime else {
            return startNewSession(user: user, timestamp: timestamp)
        }

        guard let currentSession = currentSession, timestamp.timeIntervalSince1970 - lastEventTime.timeIntervalSince1970 < sessionTimeout else {
            return startNewSession(user: user, timestamp: timestamp)
        }

        updateLastEventTime(timestamp: timestamp)
        return currentSession
    }

    func updateLastEventTime(timestamp: Date) {
        lastEventTime = timestamp
        keyValueRepository.putDouble(key: DefaultSessionManager.LAST_EVENT_TIME_KEY, value: timestamp.timeIntervalSince1970)
        Log.debug("LastEventTime updated [\(timestamp)]")
    }

    private func endSession(user: User) {
        guard let oldSession = currentSession, let lastEventTime = lastEventTime else {
            return
        }

        for listener in sessionListeners {
            listener.onSessionEnded(session: oldSession, user: user, timestamp: lastEventTime)
        }
        Log.debug("Session ended [$\(oldSession.id)]")
    }

    @discardableResult
    private func newSession(user: User, timestamp: Date) -> Session {
        let newSession = Session.create(timestamp: timestamp)
        currentSession = newSession
        saveSession(session: newSession)

        updateLastEventTime(timestamp: timestamp)

        for listener in sessionListeners {
            listener.onSessionStarted(session: newSession, user: user, timestamp: timestamp)
        }
        Log.debug("Session started [\(newSession.id)]")
        return newSession
    }

    private func saveSession(session: Session) {
        keyValueRepository.putString(key: DefaultSessionManager.SESSION_ID_KEY, value: session.id)
        Log.debug("Session saved [\(session.id)]")
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

    func onChanged(state: AppState, timestamp: Date) {
        switch state {
        case .foreground:
            startNewSessionIfNeeded(user: userManager.currentUser, timestamp: timestamp)
        case .background:
            updateLastEventTime(timestamp: timestamp)
            guard let session = currentSession else {
                return
            }
            saveSession(session: session)
        }
    }

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        endSession(user: oldUser)
        newSession(user: newUser, timestamp: timestamp)
    }
}
