import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultSessionManagerSpecs: QuickSpec {
    override func spec() {

        var eventQueue: DispatchQueue!
        var keyValueRepository: KeyValueRepositoryStub!
        var listener: SessionListenerStub!

        beforeEach {
            eventQueue = DispatchQueue(label: "test.EventQueue")
            keyValueRepository = KeyValueRepositoryStub()
            listener = SessionListenerStub()
        }

        func manager(
            sessionTimeoutInterval: TimeInterval = 10
        ) -> DefaultSessionManager {
            let sut = DefaultSessionManager(
                eventQueue: eventQueue,
                keyValueRepository: keyValueRepository,
                sessionTimeout: sessionTimeoutInterval
            )
            sut.addListener(listener: listener)
            return sut
        }

        it("requiredSession") {

            let sut = manager()
            expect(sut.requiredSession.id) == "0.ffffffff"
            sut.startNewSession(timestamp: Date(timeIntervalSince1970: 42))
            expect(sut.requiredSession.id.hasPrefix("42000.")) == true
        }

        it("startNewSession") {
            let sut = manager()

            let s1 = sut.startNewSession(timestamp: Date(timeIntervalSince1970: 42))
            expect(s1.id.hasPrefix("42000.")) == true
            expect(listener.sessionStarted.count) == 1
            expect(listener.sessionStarted[0].0) == s1
            expect(listener.sessionStarted[0].1) == Date(timeIntervalSince1970: 42)
            expect(listener.sessionEnded.count) == 0
            expect(keyValueRepository.getString(key: "session_id")) == s1.id

            let s2 = sut.startNewSession(timestamp: Date(timeIntervalSince1970: 43))
            expect(s2.id.hasPrefix("43000.")) == true
            expect(listener.sessionStarted.count) == 2
            expect(listener.sessionStarted[1].0) == s2
            expect(listener.sessionStarted[1].1) == Date(timeIntervalSince1970: 43)

            expect(listener.sessionEnded.count) == 1
            expect(listener.sessionEnded[0].0) == s1
            expect(listener.sessionEnded[0].1) == Date(timeIntervalSince1970: 42)
            expect(keyValueRepository.getString(key: "session_id")) == s2.id
        }

        describe("startNewSessionIfNeeded") {
            it("lastEventTime 이 없으면 세션을 시작한다") {
                // given
                let sut = manager()

                // when
                let actual = sut.startNewSessionIfNeeded(timestamp: Date(timeIntervalSince1970: 42))

                // then
                expect(actual.id.hasPrefix("42000.")) == true
                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
            }

            it("세션 만료전이면 기존 세션을 리턴한다") {
                let sut = manager(sessionTimeoutInterval: 10)

                let s1 = sut.startNewSession(timestamp: Date(timeIntervalSince1970: 42))
                let s2 = sut.startNewSessionIfNeeded(timestamp: Date(timeIntervalSince1970: 51.999))

                expect(s1) == s2
                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 51.999)
            }

            it("세션이 만료됐으면 새로운 세션을 시작한다") {
                let sut = manager(sessionTimeoutInterval: 10)

                let s1 = sut.startNewSession(timestamp: Date(timeIntervalSince1970: 42))
                let s2 = sut.startNewSessionIfNeeded(timestamp: Date(timeIntervalSince1970: 52))

                expect(s1) != s2
                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 52)
                expect(listener.sessionStarted[1].0) == s2
                expect(listener.sessionEnded[0].0) == s1
            }
        }

        it("updateLastEventTime") {
            let sut = manager()
            expect(sut.lastEventTime).to(beNil())
            sut.updateLastEventTime(timestamp: Date(timeIntervalSince1970: 42))
            expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
            expect(keyValueRepository.getDouble(key: "last_event_time")) == 42.0
        }

        describe("onInitialized") {
            it("저장된 세션이 없으면 nil") {
                // given
                let sut = manager()

                // when
                sut.onInitialized()
                eventQueue.sync {
                }

                // then
                expect(sut.currentSession).to(beNil())
            }

            it("저장된 세션이 있는 경우") {
                // given
                let sut = manager()
                keyValueRepository.putString(key: "session_id", value: "42")

                // when
                sut.onInitialized()
                eventQueue.sync {
                }

                // then
                expect(sut.currentSession) == Session(id: "42")
            }

            it("저장되어있는 LastEventTime 이 있는 경우") {
                // given
                let sut = manager()
                keyValueRepository.putDouble(key: "last_event_time", value: 42.0)

                // when
                sut.onInitialized()
                eventQueue.sync {
                }

                // then
                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
            }

            it("저장되어있는 LastEventTime 이 없는 경우") {
                // given
                let sut = manager()

                // when
                sut.onInitialized()
                eventQueue.sync {
                }

                // then
                expect(sut.lastEventTime).to(beNil())
            }
        }

        describe("onNotified") {
            it("FOREGROUND 세션 초기화 시도") {
                let sut = manager()
                expect(sut.currentSession).to(beNil())

                sut.onNotified(notification: .didBecomeActive, timestamp: Date(timeIntervalSince1970: 42))
                eventQueue.sync {
                }

                expect(sut.requiredSession.id.hasPrefix("42000."))
            }

            it("BACKGROUND 현재 세션을 저장한다") {
                // given
                let sut = manager()
                sut.startNewSession(timestamp: Date(timeIntervalSince1970: 42))

                // when
                sut.onNotified(notification: .didEnterBackground, timestamp: Date(timeIntervalSince1970: 43))
                eventQueue.sync {
                }

                // then
                expect(keyValueRepository.getString(key: "session_id")?.hasPrefix("42000.")) == true
            }

            it("백그라운드로 넘어기면 전달받은 timestamp 로 업데이트한다") {
                // given
                let sut = manager()

                // when
                sut.onNotified(notification: .didEnterBackground, timestamp: Date(timeIntervalSince1970: 42))
                eventQueue.sync {
                }

                // then
                expect(keyValueRepository.getDouble(key: "last_event_time")) == 42.0
            }
        }

        describe("onUserUpdated") {

            it("세션을 새로 시작한다") {
                // given
                let sut = manager()

                // when
                sut.onUserUpdated(user: HackleUser.of(userId: "hi"), timestamp: Date(timeIntervalSince1970: 42))

                // then
                expect(sut.currentSession?.id.hasPrefix("42000.")) == true
            }
        }
    }
}

fileprivate class KeyValueRepositoryStub: KeyValueRepository {

    var map = [String: Any]()

    func getString(key: String) -> String? {
        map[key] as? String
    }

    func putString(key: String, value: String) {
        map[key] = value
    }

    func getDouble(key: String) -> Double {
        map[key] as? Double ?? 0.0
    }

    func putDouble(key: String, value: Double) {
        map[key] = value
    }
}

fileprivate class SessionListenerStub: SessionListener {

    var sessionStarted = [(Session, Date)]()
    var sessionEnded = [(Session, Date)]()

    func onSessionStarted(session: Session, timestamp: Date) {
        sessionStarted.append((session, timestamp))
    }

    func onSessionEnded(session: Session, timestamp: Date) {
        sessionEnded.append((session, timestamp))
    }
}
