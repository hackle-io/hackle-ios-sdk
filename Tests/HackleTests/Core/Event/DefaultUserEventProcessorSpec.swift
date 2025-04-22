import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultUserEventProcessorSpec: QuickSpec {

    override func spec() {

        let user = HackleUser.of(userId: "test_id")

        var eventDedupDeterminer: MockUserEventDedupDeterminer!
        var eventPublisher: UserEventPublisherStub!
        var eventQueue: DispatchQueue!
        var eventRepository: MockEventRepository!
        var eventFlushScheduler: MockScheduler!
        var eventDispatcher: MockUserEventDispatcher!
        var sessionManager: MockSessionManager!
        var userManager: MockUserManager!
        var appStateManager: AppStateManagerStub!
        var screenManager: MockScreeManager!

        beforeEach {
            eventDedupDeterminer = MockUserEventDedupDeterminer()
            eventPublisher = UserEventPublisherStub()
            eventQueue = DispatchQueue(label: "test.EventQueue")
            eventRepository = MockEventRepository()
            eventFlushScheduler = MockScheduler()
            eventDispatcher = MockUserEventDispatcher()
            sessionManager = MockSessionManager()
            userManager = MockUserManager()
            appStateManager = AppStateManagerStub(currentState: .foreground)
            screenManager = MockScreeManager()

            every(eventDedupDeterminer.isDedupTargetMock).returns(false)
            every(eventRepository.countMock).returns(0)
            every(eventRepository.countByMock).returns(0)
            every(eventRepository.getEventToFlushMock).returns([])
        }

        func processor(
            eventFilters: [UserEventFilter] = [],
            eventDecorator: [UserEventDecorator] = [
                ScreenUserEventDecorator(screenManager: screenManager),
                SessionUserEventDecorator(sessionManager: sessionManager)
            ],
            eventQueue: DispatchQueue = eventQueue,
            eventRepository: EventRepository = eventRepository,
            eventRepositoryMaxSize: Int = 100,
            eventFlushScheduler: Scheduler = eventFlushScheduler,
            eventFlushInterval: TimeInterval = 10,
            eventFlushThreshold: Int = 10,
            eventFlushMaxBatchSize: Int = 21,
            eventDispatcher: UserEventDispatcher = eventDispatcher,
            sessionManager: SessionManager = sessionManager,
            userManager: UserManager = userManager,
            appStateManager: AppStateManagerStub = appStateManager
        ) -> DefaultUserEventProcessor {
            DefaultUserEventProcessor(
                eventFilters: eventFilters,
                eventDecorator: eventDecorator,
                eventPublisher: eventPublisher,
                eventQueue: eventQueue,
                eventRepository: eventRepository,
                eventRepositoryMaxSize: eventRepositoryMaxSize,
                eventFlushScheduler: eventFlushScheduler,
                eventFlushInterval: eventFlushInterval,
                eventFlushThreshold: eventFlushThreshold,
                eventFlushMaxBatchSize: eventFlushMaxBatchSize,
                eventDispatcher: eventDispatcher,
                sessionManager: sessionManager,
                userManager: userManager,
                appStateManager: appStateManager,
                screenManager: screenManager
            )
        }

        describe("process") {

            it("when current screen is nil then do not decorate") {
                // given
                let sut = processor()
                let event = UserEvents.track("test")

                // when
                sut.process(event: event)
                eventQueue.await()

                // then
                verify(exactly: 1) {
                    eventRepository.saveMock
                }
                let savedEvent = eventRepository.saveMock.firstInvokation().arguments
                expect(savedEvent.user.hackleProperties["screenName"]).to(beNil())
            }

            it("decorate screenName") {
                // given
                let sut = processor()
                screenManager.currentScreen = Screen(name: "name", className: "class")
                let event = UserEvents.track("test")

                // when
                sut.process(event: event)
                eventQueue.await()

                // then
                verify(exactly: 1) {
                    eventRepository.saveMock
                }
                let savedEvent = eventRepository.saveMock.firstInvokation().arguments
                expect(savedEvent.user.hackleProperties["screenName"] as! String).to(equal("name"))
                expect(savedEvent.user.hackleProperties["screenClass"] as! String).to(equal("class"))
            }

            it("SessionEvent 인 경우 lastEventTime 을 업데이트 하지 않는다") {
                // given
                let sut = processor()
                let user = HackleUser.builder().identifier(.id, "id").build()
                let event = UserEvents.track(eventType: UndefinedEventType(key: "$session_start"), event: Hackle.event(key: "$session_start"), timestamp: Date(), user: user)

                // when
                sut.process(event: event)

                // then
                verify(exactly: 0) {
                    sessionManager.updateLastEventTimeMock
                }
            }


            it("update lastEventTime") {
                // given
                let sut = processor()
                let event = MockUserEvent(user: user, timestamp: Date(timeIntervalSince1970: 42))

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    sessionManager.updateLastEventTimeMock
                }

                expect(sessionManager.updateLastEventTimeMock.firstInvokation().arguments.timeIntervalSince1970) == 42
            }

            it("foreground 가 아닌경우 세션초기화 시도") {
                // given
                let sut = processor(appStateManager: AppStateManagerStub(currentState: .background))
                let event = MockUserEvent(user: user, timestamp: Date(timeIntervalSince1970: 42))
                every(sessionManager.startNewSessionIfNeededMock).returns(Session(id: "session_id"))

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    sessionManager.startNewSessionIfNeededMock
                }
            }

            it("중복제거 대상이면 이벤트를 저장하지 않는다") {
                // given
                every(eventDedupDeterminer.isDedupTargetMock).returns(true)

                let sut = processor(
                    eventFilters: [DedupUserEventFilter(eventDedupDeterminer: eventDedupDeterminer)]
                )
                let event = MockUserEvent(user: user)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 0) {
                    eventRepository.saveMock
                }
            }

            it("currentSession 이 없으면 sessionId 를 추가하지 않는다") {
                // given
                let sut = processor()
                let event = MockUserEvent(user: user)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    eventRepository.saveMock
                }
                expect(eventRepository.saveMock.firstInvokation().arguments).to(beIdenticalTo(event))
            }

            it("currentSession 의 sessionId 를 추가한다") {
                // given
                let sut = processor()
                let event = MockUserEvent(user: user)
                sessionManager.currentSession = Session(id: "42.session")

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    eventRepository.saveMock
                }
                let actualEvent = eventRepository.saveMock.firstInvokation().arguments
                expect(actualEvent.user.identifiers.count) == 2
                expect(actualEvent.user.identifiers[IdentifierType.session.rawValue]) == "42.session"

            }

            it("입력받은 이벤트를 저장한다") {
                // given
                let sut = processor()
                let event = MockUserEvent(user: user)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    eventRepository.saveMock
                }
            }

            it("이벤트 저장 후 저장된 이벤트의 갯수가 최대 저장 갯수보다 큰 경우 오래된 이벤트를 삭제한다") {
                // given
                let sut = processor(
                    eventRepositoryMaxSize: 100,
                    eventFlushThreshold: 42,
                    eventFlushMaxBatchSize: 51
                )
                every(eventRepository.countMock).returns(101)
                let event = MockUserEvent(user: user)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    eventRepository.deleteOldEventsMock
                }
            }

            it("이벤트 저장 후 Pending 이벤트 갯수가 임계치랑 같은 경우 Flush 한다") {
                // given
                let sut = processor(
                    eventRepositoryMaxSize: 100,
                    eventFlushThreshold: 15,
                    eventFlushMaxBatchSize: 42
                )
                every(eventRepository.countMock).returns(100)
                every(eventRepository.countByMock).returns(15)

                let events = [EventEntity(id: 320, type: .exposure, status: .pending, body: "body")]
                every(eventRepository.getEventToFlushMock).returns(events)

                let event = MockUserEvent(user: user)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    eventDispatcher.dispatchMock
                }
            }

            it("이벤트 저장 후 Pending 이벤트 갯수가 임계치의 배수이면 Flush 한다") {
                // given
                let sut = processor(
                    eventRepositoryMaxSize: 100,
                    eventFlushThreshold: 15,
                    eventFlushMaxBatchSize: 42
                )
                every(eventRepository.countMock).returns(100)
                every(eventRepository.countByMock).returns(30)

                let events = [EventEntity(id: 320, type: .exposure, status: .pending, body: "body")]
                every(eventRepository.getEventToFlushMock).returns(events)

                let event = MockUserEvent(user: user)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    eventDispatcher.dispatchMock
                }
            }

            it("Pending 이벤트가 임계치보다 크지만 배수가 아닌경우 Flush 하지 않는다") {
                // given
                let sut = processor(
                    eventRepositoryMaxSize: 100,
                    eventFlushThreshold: 15,
                    eventFlushMaxBatchSize: 42
                )
                every(eventRepository.countMock).returns(100)
                every(eventRepository.countByMock).returns(29)

                let events = [EventEntity(id: 320, type: .exposure, status: .pending, body: "body")]
                every(eventRepository.getEventToFlushMock).returns(events)

                let event = MockUserEvent(user: user)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 0) {
                    eventDispatcher.dispatchMock
                }
            }

            it("publish") {
                // given
                let sut = processor()
                let event: UserEvent = UserEvents.track("test")

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.process(event: event)
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                expect(eventPublisher.events.count) == 1
                let publishedEvent = eventPublisher.events[0]
                expect(publishedEvent.insertId) == event.insertId
            }
        }

        describe("onNotified") {
            var spy: OnNotifiedSpy!
            beforeEach {
                spy = OnNotifiedSpy(
                    eventFilters: [],
                    eventDecorator: [],
                    eventPublisher: eventPublisher,
                    eventQueue: eventQueue,
                    eventRepository: eventRepository,
                    eventRepositoryMaxSize: 100,
                    eventFlushScheduler: eventFlushScheduler,
                    eventFlushInterval: 10,
                    eventFlushThreshold: 10,
                    eventFlushMaxBatchSize: 21,
                    eventDispatcher: eventDispatcher,
                    sessionManager: sessionManager,
                    userManager: userManager,
                    appStateManager: appStateManager,
                    screenManager: MockScreeManager()
                )
            }

            context("didEnterBackground 노티인 경우") {
                it("stop() 을 호출한다") {
                    spy.onState(state: .background, timestamp: Date())
                    expect(spy.stopCalled) == true
                }
            }

            context("didBecomeActive 노티인 경우") {
                it("start() 를 호출한다") {
                    spy.onState(state: .foreground, timestamp: Date())
                    expect(spy.startCalled) == true
                }
            }
        }

        describe("initialize") {

            it("Flushing 상태의 이벤트를 Pending 상태로 바꾼다") {
                // given
                let sut = processor()
                every(eventFlushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())
                let events = [EventEntity(id: 320, type: .exposure, status: .pending, body: "body")]
                every(eventRepository.findAllByMock).returns(events)

                // when
                sut.initialize()

                // then
                expect(eventRepository.updateMock.invokations()[0].arguments.0).to(beIdenticalTo(events))
                expect(eventRepository.updateMock.invokations()[0].arguments.1) == EventEntityStatus.pending
            }

            it("Flushing 상태의 이벤트가 없으면 별도 처리 하지 않는다") {
                // given
                let sut = processor()
                every(eventFlushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())
                let events = [EventEntity]()
                every(eventRepository.findAllByMock).returns(events)

                // when
                sut.initialize()

                // then
                verify(exactly: 0) {
                    eventRepository.updateMock
                }
            }

        }

        describe("start") {

            it("flush 스케줄링을 시작한다") {
                // given
                let sut = processor()
                every(eventFlushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())

                // when
                sut.start()

                // then
                verify(exactly: 1) {
                    eventFlushScheduler.schedulePeriodicallyMock
                }

                verify(exactly: 0) {
                    eventRepository.getEventToFlushMock
                }

                let flushTask = eventFlushScheduler.schedulePeriodicallyMock.firstInvokation().arguments.2
                flushTask()

                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    eventQueue.sync {
                        done()
                    }
                }

                verify(exactly: 1) {
                    eventRepository.getEventToFlushMock
                }
            }

            context("이미 스케줄링이 시작되어있으면") {
                it("아무것도 하지않고 리턴한다") {
                    // given
                    let sut = processor()
                    every(eventFlushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())
                    sut.start()

                    // when
                    sut.start()

                    // then
                    verify(exactly: 1) {
                        eventFlushScheduler.schedulePeriodicallyMock
                    }
                }
            }

            context("여러번 호출해도") {
                it("스케줄링은 한번만 실행된다") {
                    let sut = processor()
                    every(eventFlushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())

                    let q = DispatchQueue.concurrent()

                    for _ in 1...100 {
                        q.async {
                            sut.start()
                        }
                    }

                    q.await()

                    verify(exactly: 1) {
                        eventFlushScheduler.schedulePeriodicallyMock
                    }
                }
            }
        }

        it("stop") {
            let sut = processor()

            let scheduledJob = MockScheduledJob()
            every(eventFlushScheduler.schedulePeriodicallyMock).returns(scheduledJob)

            sut.start()
            verify(exactly: 1) {
                eventFlushScheduler.schedulePeriodicallyMock
            }

            sut.stop()
            Nimble.waitUntil(timeout: .seconds(2)) { done in
                eventQueue.sync {
                    done()
                }
            }
            verify(exactly: 1) {
                eventRepository.getEventToFlushMock
            }

            sut.start()
            verify(exactly: 2) {
                eventFlushScheduler.schedulePeriodicallyMock
            }

            // then
            expect(scheduledJob.cancelMock.wasCalled()) == true
        }

        context("dispatch") {

            it("limit 가 0보다 작으면 실행하지 않는다") {
                // given
                let sut = processor(eventFlushMaxBatchSize: 0)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.flush()
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 0) {
                    eventRepository.getEventToFlushMock
                }

                verify(exactly: 0) {
                    eventDispatcher.dispatchMock
                }
            }

            it("전송할 이벤트가 없으면 전송하지 않는다") {
                // given
                let sut = processor(eventFlushMaxBatchSize: 1)
                every(eventRepository.getEventToFlushMock).returns([])

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.flush()
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 0) {
                    eventDispatcher.dispatchMock
                }
            }

            it("이벤트를 전송한다") {
                // given
                let sut = processor(eventFlushMaxBatchSize: 1)

                let events = [EventEntity(id: 320, type: .exposure, status: .pending, body: "body")]
                every(eventRepository.getEventToFlushMock).returns(events)

                // when
                Nimble.waitUntil(timeout: .seconds(2)) { done in
                    sut.flush()
                    eventQueue.sync {
                        done()
                    }
                }

                // then
                verify(exactly: 1) {
                    eventDispatcher.dispatchMock
                }
            }
        }
    }
}

fileprivate class OnNotifiedSpy: DefaultUserEventProcessor {

    var startCalled = false
    var stopCalled = false

    override func start() {
        startCalled = true
    }

    override func stop() {
        stopCalled = true
    }
}
