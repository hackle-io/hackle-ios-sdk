//import Foundation
//import Quick
//import Nimble
//import Mockery
//@testable import Hackle
//
//class DefaultSessionManagerSpecs: QuickSpec {
//    override func spec() {
//
//        func manager(
//            sessionTimeoutInterval: TimeInterval = 10,
//            repository: KeyValueRepository = MemoryKeyValueRepository(),
//            _ listeners: SessionListener...
//        ) -> DefaultSessionManager {
//            let sut = DefaultSessionManager(
//                userManager: DefaultUserManager(
//                    device: MockDevice(id: "test_id", properties: [:]),
//                    repository: MemoryKeyValueRepository()
//                ),
//                keyValueRepository: repository,
//                sessionTimeout: sessionTimeoutInterval
//            )
//            for listener in listeners {
//                sut.addListener(listener: listener)
//            }
//            return sut
//        }
//
//        it("requiredSession") {
//            let sut = manager()
//            expect(sut.requiredSession.id) == "0.ffffffff"
//            sut.startNewSession(user: User.builder().id("hello").build(), timestamp: Date(timeIntervalSince1970: 42))
//            expect(sut.requiredSession.id.hasPrefix("42000.")) == true
//        }
//
//        describe("initialize") {
//            it("저장된 데이터가 있는 경우") {
//                let repository = MemoryKeyValueRepository(dict: ["session_id": "42.ffffffff", "last_event_time": 42.0])
//                let sut = manager(repository: repository)
//
//                sut.initialize()
//
//                expect(sut.currentSession?.id) == "42.ffffffff"
//                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
//            }
//
//            it("저장된 데이터가 없는 경우") {
//                let sut = manager(repository: MemoryKeyValueRepository())
//
//                sut.initialize()
//
//                expect(sut.currentSession).to(beNil())
//                expect(sut.lastEventTime).to(beNil())
//            }
//        }
//
//        it("startNewSession") {
//
//            let repository = MemoryKeyValueRepository()
//            let listener = SessionListenerStub()
//            let sut = manager(repository: repository, listener)
//
//            expect(sut.currentSession).to(beNil())
//            expect(sut.lastEventTime).to(beNil())
//
//            let user1 = User.builder().id("user1").build()
//            let session1 = sut.startNewSession(user: user1, timestamp: Date(timeIntervalSince1970: 42))
//
//            expect(session1.id.hasPrefix("42000.")) == true
//            expect(sut.currentSession) == session1
//            expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
//            expect(listener.started.count) == 1
//            expect(listener.started[0].0) == session1
//            expect(listener.started[0].1.id) == "user1"
//            expect(listener.ended.count) == 0
//
//            let user2 = User.builder().id("user2").build()
//            let session2 = sut.startNewSession(user: user2, timestamp: Date(timeIntervalSince1970: 43))
//
//            expect(session2.id.hasPrefix("43000.")) == true
//            expect(sut.currentSession) == session2
//            expect(sut.lastEventTime) == Date(timeIntervalSince1970: 43)
//            expect(listener.started.count) == 2
//            expect(listener.started[0].0) == session1
//            expect(listener.started[1].0) == session2
//            expect(listener.started[1].1.id) == "user2"
//            expect(listener.ended.count) == 1
//            expect(listener.ended[0].0) == session1
//            expect(repository.getString(key: "session_id")) == session2.id
//            expect(repository.getDouble(key: "last_event_time")) == 43
//        }
//
//        describe("startNewSessionIfNeeded") {
//            it("lastEventTime 이 없으면 세션을 시작한다") {
//                let repository = MemoryKeyValueRepository()
//                let listener = SessionListenerStub()
//                let sut = manager(repository: repository, listener)
//
//                let session = sut.startNewSessionIfNeeded(user: User.builder().id("hello").build(), timestamp: Date(timeIntervalSince1970: 42))
//
//                expect(session.id.starts(with: "42000.")) == true
//                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
//            }
//
//            it("세션 만료전이면 기존 세션을 리턴한다") {
//                let repository = MemoryKeyValueRepository()
//                let listener = SessionListenerStub()
//                let sut = manager(sessionTimeoutInterval: 10, repository: repository, listener)
//
//                let user = User.builder().id("hello").build()
//
//                let session1 = sut.startNewSession(user: user, timestamp: Date(timeIntervalSince1970: 42))
//                let session2 = sut.startNewSessionIfNeeded(user: user, timestamp: Date(timeIntervalSince1970: 51))
//
//                expect(session1) == session2
//                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 51)
//            }
//
//            it("세션이 만료됐으면 새로운 세션을 시작한다") {
//                let repository = MemoryKeyValueRepository()
//                let listener = SessionListenerStub()
//                let sut = manager(sessionTimeoutInterval: 10, repository: repository, listener)
//
//                let user = User.builder().id("hello").build()
//
//                let session1 = sut.startNewSession(user: user, timestamp: Date(timeIntervalSince1970: 42))
//                let session2 = sut.startNewSessionIfNeeded(user: user, timestamp: Date(timeIntervalSince1970: 52))
//
//                expect(session1) != session2
//                expect(sut.lastEventTime) == Date(timeIntervalSince1970: 52)
//                expect(listener.started.count) == 2
//                expect(listener.started[0].0) == session1
//                expect(listener.started[1].0) == session2
//                expect(listener.ended.count) == 1
//                expect(listener.ended[0].0) == session1
//            }
//        }
//
//        it("updateLastEventTime") {
//            let repository = MemoryKeyValueRepository()
//            let listener = SessionListenerStub()
//            let sut = manager(sessionTimeoutInterval: 10, repository: repository, listener)
//
//            expect(sut.lastEventTime).to(beNil())
//            sut.updateLastEventTime(timestamp: Date(timeIntervalSince1970: 42))
//            expect(sut.lastEventTime) == Date(timeIntervalSince1970: 42)
//            expect(repository.getDouble(key: "last_event_time")) == 42.0
//        }
//
//
//        describe("onNotified") {
//            it("FOREGROUND 세션 초기화 시도") {
//                let repository = MemoryKeyValueRepository()
//                let listener = SessionListenerStub()
//                let sut = manager(sessionTimeoutInterval: 10, repository: repository, listener)
//
//                expect(sut.currentSession).to(beNil())
//                sut.onChanged(state: .foreground, timestamp: Date(timeIntervalSince1970: 42))
//
//                expect(sut.requiredSession.id.hasPrefix("42000."))
//            }
//
//            it("BACKGROUND 현재 세션을 저장한다") {
//                // given
//                let repository = MemoryKeyValueRepository()
//                let listener = SessionListenerStub()
//                let sut = manager(sessionTimeoutInterval: 10, repository: repository, listener)
//
//                sut.startNewSession(user: User.builder().id("hello").build(), timestamp: Date(timeIntervalSince1970: 42))
//
//                // when
//                sut.onChanged(state: .background, timestamp: Date(timeIntervalSince1970: 43))
//
//                // then
//                expect(repository.getString(key: "session_id")?.hasPrefix("42000.")) == true
//            }
//
//            it("백그라운드로 넘어기면 전달받은 timestamp 로 업데이트한다") {
//                // given
//                let repository = MemoryKeyValueRepository()
//                let listener = SessionListenerStub()
//                let sut = manager(sessionTimeoutInterval: 10, repository: repository, listener)
//
//                // when
//                sut.onChanged(state: .background, timestamp: Date(timeIntervalSince1970: 42))
//
//                // then
//                expect(repository.getDouble(key: "last_event_time")) == 42.0
//            }
//        }
//    }
//}
//
//fileprivate class SessionListenerStub: SessionListener {
//
//    var started = [(Session, User, Date)]()
//    var ended = [(Session, User, Date)]()
//
//    func onSessionStarted(session: Session, user: User, timestamp: Date) {
//        started.append((session, user, timestamp))
//    }
//
//    func onSessionEnded(session: Session, user: User, timestamp: Date) {
//        ended.append((session, user, timestamp))
//    }
//}
