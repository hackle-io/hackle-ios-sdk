//
// Created by yong on 2020/12/20.
//

import Foundation
import Quick
import Nimble
@testable import Hackle

class DefaultUserEventProcessorSpec: QuickSpec {

    override func spec() {

        var user = HackleUser.of(userId: "test_id")

        var eventQueue: ConcurrentArray<UserEvent>!
        var eventDispatcher: MockUserEventDispatcher!
        var maxEventDispatchSize: Int = 20
        var flushScheduler: MockScheduler!
        var flushInterval: TimeInterval = 60.0
        var eventDedupDeterminer: MockExposureEventDedupDeterminer!
        var sut: DefaultUserEventProcessor!

        beforeEach {
            eventQueue = ConcurrentArray()
            eventDispatcher = MockUserEventDispatcher()
            flushScheduler = MockScheduler()
            eventDedupDeterminer = MockExposureEventDedupDeterminer()
            every(eventDedupDeterminer.isDedupTargetMock).returns(false)
            sut = DefaultUserEventProcessor(
                eventQueue: eventQueue,
                eventDispatcher: eventDispatcher,
                eventDispatchSize: maxEventDispatchSize,
                flushScheduler: flushScheduler,
                flushInterval: flushInterval,
                eventDedupDeterminer: eventDedupDeterminer
            )
        }

        describe("process") {
            it("이벤트를 큐에 쌓는다") {
                // given
                var event = MockUserEvent(user: user)

                // when
                sut.process(event: event)

                // then
                expect(eventQueue.size) == 1
                expect(eventQueue.take()!).to(beIdenticalTo(event))
            }

            context("이벤트를 큐에 쌓은 이후") {
                context("큐에 적재된 이벤트 갯수가 maxEventDispatchSize 보다 크거나 같으면") {
                    it("큐에 있던 이벤트를 전송하고 큐를 비운다") {
                        // given
                        for _ in 1...maxEventDispatchSize - 1 {
                            eventQueue.add(MockUserEvent(user: user))
                        }

                        // when
                        sut.process(event: MockUserEvent(user: user))

                        // then
                        expect(eventQueue.isEmpty) == true
                        expect(eventDispatcher.dispatchMock.wasCalled()) == true
                        expect(eventDispatcher.dispatchMock.invokations()[0].arguments.count) == 20
                    }
                }
                context("큐에 적재된 이벤트 갯수가 maxEventDispatchSize 보다 작으면") {
                    it("이벤트를 전송하지 않는다") {
                        // given
                        for _ in 1...maxEventDispatchSize - 2 {
                            eventQueue.add(MockUserEvent(user: user))
                        }

                        // when
                        sut.process(event: MockUserEvent(user: user))

                        // then
                        expect(eventQueue.isEmpty) == false
                        expect(eventDispatcher.dispatchMock.wasNotCalled()) == true
                    }
                }
            }
        }

        describe("flush") {

            context("큐에 이벤트가 있으면") {
                it("이벤트를 전송하고 큐를 비운다") {
                    // given
                    eventQueue.add(MockUserEvent(user: user))

                    // when
                    sut.flush()

                    // then
                    expect(eventQueue.isEmpty) == true
                    expect(eventDispatcher.dispatchMock.wasCalled()) == true
                }
            }

            context("큐가 비어있으면") {
                it("전송하지 않는다") {
                    // given
                    eventQueue.takeAll()

                    // when
                    sut.flush()

                    // then
                    expect(eventDispatcher.dispatchMock.wasNotCalled()) == true
                }
            }
        }

        describe("start") {

            it("flush 스케줄링을 시작한다") {
                // given
                every(flushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())
                eventQueue.add(MockUserEvent(user: user))

                // when
                sut.start()

                // then
                expect(flushScheduler.schedulePeriodicallyMock.wasCalled(exactly: 1)) == true

                expect(eventQueue.isEmpty) == false
                let flushTask = flushScheduler.schedulePeriodicallyMock.invokations()[0].arguments.2
                flushTask()
                expect(eventQueue.isEmpty) == true
            }

            context("이미 스케줄링이 시작되어있으면") {
                it("아무것도 하지않고 리턴한다") {
                    // given
                    every(flushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())
                    sut.start()

                    // when
                    sut.start()

                    // then
                    expect(flushScheduler.schedulePeriodicallyMock.wasCalled(exactly: 1)) == true
                }
            }

            context("여러번 호출해도") {
                it("스케줄링은 한번만 실행된다") {
                    every(flushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())

                    let q = DispatchQueue(label: "test", attributes: .concurrent)

                    for _ in 1...100 {
                        q.async {
                            sut.start()
                        }
                    }

                    expect(flushScheduler.schedulePeriodicallyMock.wasCalled(exactly: 1)) == true
                }
            }
        }

        describe("stop") {
            it("스케줄링을 취소한다") {
                // given
                let scheduledJob = MockScheduledJob()
                every(flushScheduler.schedulePeriodicallyMock).returns(scheduledJob)

                // when
                sut.start()
                sut.stop()

                // then
                expect(scheduledJob.cancelMock.wasCalled()) == true
            }

            it("flush를 호출한다") {
                // given
                eventQueue.add(MockUserEvent(user: user))
                every(flushScheduler.schedulePeriodicallyMock).returns(MockScheduledJob())

                // when
                sut.start()
                sut.stop()

                // then
                expect(eventDispatcher.dispatchMock.wasCalled()) == true
            }
        }

        describe("onNotified") {
            var spy: OnNotifiedSpy!
            beforeEach {
                spy = OnNotifiedSpy(
                    eventQueue: eventQueue,
                    eventDispatcher: eventDispatcher,
                    eventDispatchSize: maxEventDispatchSize,
                    flushScheduler: flushScheduler,
                    flushInterval: flushInterval,
                    eventDedupDeterminer: eventDedupDeterminer
                )
            }

            context("didEnterBackground 노티인 경우") {
                it("stop() 을 호출한다") {
                    spy.onNotified(notification: .didEnterBackground)
                    expect(spy.stopCalled) == true
                }
            }

            context("didBecomeActive 노티인 경우") {
                it("start() 를 호출한다") {
                    spy.onNotified(notification: .didBecomeActive)
                    expect(spy.startCalled) == true
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
