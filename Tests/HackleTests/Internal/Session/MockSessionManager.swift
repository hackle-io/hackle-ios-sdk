import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockSessionManager: Mock, SessionManager {
    private(set) var requiredSession: Session
    private(set) var currentSession: Session? = nil
    private(set) var lastEventTime: Date? = nil

    init(requiredSession: Session = Session.UNKNOWN, currentSession: Session? = nil, lastEventTime: Date? = nil) {
        self.requiredSession = requiredSession
        self.currentSession = currentSession
        self.lastEventTime = lastEventTime
        super.init()
    }

    lazy var startNewSessionMock = MockFunction(self, startNewSession)

    func startNewSession(timestamp: Date) -> Session {
        call(startNewSessionMock, args: timestamp)
    }

    lazy var startNewSessionIfNeededMock = MockFunction(self, startNewSessionIfNeeded)

    func startNewSessionIfNeeded(timestamp: Date) -> Session {
        call(startNewSessionIfNeededMock, args: timestamp)
    }

    lazy var updateLastEventTimeMock = MockFunction(self, updateLastEventTime)

    func updateLastEventTime(timestamp: Date) {
        call(updateLastEventTimeMock, args: timestamp)
    }
}