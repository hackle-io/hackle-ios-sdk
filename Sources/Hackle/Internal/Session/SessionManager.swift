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

    func startNewSession(timestamp: Date) -> Session

    func startNewSessionIfNeeded(timestamp: Date) -> Session

    func updateLastEventTime(timestamp: Date)
}

class DefaultSessionManager: SessionManager, AppInitializeListener, AppNotificationListener, UserListener {

    private let eventQueue: DispatchQueue
    private let keyValueRepository: KeyValueRepository
    private let sessionTimeout: TimeInterval
    private var sessionListeners: [SessionListener]

    var requiredSession: Session {
        currentSession ?? Session.UNKNOWN
    }

    private(set) var currentSession: Session? = nil
    private(set) var lastEventTime: Date? = nil

    init(eventQueue: DispatchQueue, keyValueRepository: KeyValueRepository, sessionTimeout: TimeInterval) {
        self.eventQueue = eventQueue
        self.keyValueRepository = keyValueRepository
        self.sessionTimeout = sessionTimeout
        self.sessionListeners = []
    }

    private static let SESSION_ID_KEY = "session_id"
    private static let LAST_EVENT_TIME_KEY = "last_event_time"

    func addListener(listener: SessionListener) {
        self.sessionListeners.append(listener)
    }

    func startNewSession(timestamp: Date) -> Session {
        endSession()
        return newSession(timestamp: timestamp)
    }

    func startNewSessionIfNeeded(timestamp: Date) -> Session {
        guard let lastEventTime = lastEventTime else {
            return startNewSession(timestamp: timestamp)
        }

        guard let currentSession = currentSession, timestamp.timeIntervalSince1970 - lastEventTime.timeIntervalSince1970 < sessionTimeout else {
            return startNewSession(timestamp: timestamp)
        }

        updateLastEventTime(timestamp: timestamp)
        return currentSession
    }

    func updateLastEventTime(timestamp: Date) {
        lastEventTime = timestamp
        keyValueRepository.putDouble(key: DefaultSessionManager.LAST_EVENT_TIME_KEY, value: timestamp.timeIntervalSince1970)
    }

    private func endSession() {
        guard let oldSession = currentSession, let lastEventTime = lastEventTime else {
            return
        }

        for listener in sessionListeners {
            listener.onSessionEnded(session: oldSession, timestamp: lastEventTime)
        }
    }

    private func newSession(timestamp: Date) -> Session {
        let newSession = Session.create(timestamp: timestamp)
        currentSession = newSession
        saveSession(session: newSession)

        updateLastEventTime(timestamp: timestamp)

        for listener in sessionListeners {
            listener.onSessionStarted(session: newSession, timestamp: timestamp)
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
    }

    private func loadLastEventTime() {
        let lastEventTime = keyValueRepository.getDouble(key: DefaultSessionManager.LAST_EVENT_TIME_KEY)
        if lastEventTime > 0 {
            self.lastEventTime = Date(timeIntervalSince1970: lastEventTime)
        }
    }

    func onInitialized() {
        eventQueue.async { [weak self] in
            self?.loadSession()
            self?.loadLastEventTime()
        }
    }

    func onNotified(notification: AppNotification, timestamp: Date) {
        switch notification {
        case .didBecomeActive:
            eventQueue.async { [weak self] in
                _ = self?.startNewSessionIfNeeded(timestamp: timestamp)
            }
        case .didEnterBackground:
            eventQueue.async { [weak self] in
                self?.updateLastEventTime(timestamp: timestamp)
                guard let session = self?.currentSession else {
                    return
                }
                self?.saveSession(session: session)
            }
        }
    }

    func onUserUpdated(user: HackleUser, timestamp: Date) {
        _ = startNewSession(timestamp: timestamp)
    }
}
