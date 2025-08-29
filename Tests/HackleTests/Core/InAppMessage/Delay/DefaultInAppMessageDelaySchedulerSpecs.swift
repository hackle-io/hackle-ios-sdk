import Foundation
import Nimble
import Quick

@testable import Hackle

class DefaultInAppMessageDelaySchedulerSpecs: QuickSpec {
    override func spec() {

        it("delay trigger") {
            // given
            let clock = FixedClock(date: Date(timeIntervalSince1970: 2001))
            let scheduler = MockScheduler()
            let listener = MockInAppMessageScheduleListener()

            let sut = DefaultInAppMessageDelayScheduler(
                clock: clock,
                scheduler: scheduler
            )
            sut.setListener(listsner: listener)

            let job = MockScheduledJob()
            every(scheduler.scheduleMock).answers { (delay, task) in
                task()
                return job
            }

            let schedule = InAppMessage.schedule(
                time: InAppMessageSchedule.Time(
                    startedAt: Date(timeIntervalSince1970: 1001),
                    deliverAt: Date(timeIntervalSince1970: 2000)
                )
            )
            let delay = InAppMessageDelay(
                schedule: schedule,
                requestedAt: Date(timeIntervalSince1970: 1500)
            )

            // when
            let task = sut.schedule(delay: delay)

            // then
            expect(task.delay).to(beIdenticalTo(delay))

            verify(exactly: 1) {
                scheduler.scheduleMock
            }
            let (scheduleDelay, _) = scheduler.scheduleMock.firstInvokation().arguments
            expect(scheduleDelay) == 500

            verify(exactly: 1) {
                listener.onScheduleMock
            }
            let scheduleRequest = listener.onScheduleMock.firstInvokation().arguments
            expect(scheduleRequest.scheduleType) == .delayed
            expect(scheduleRequest.requestedAt) == Date(timeIntervalSince1970: 2001)
        }

        it("task complete") {
            let sut = DefaultInAppMessageDelayScheduler(clock: SystemClock.shared, scheduler: Schedulers.dispatch())
            let listener = MockInAppMessageScheduleListener()
            sut.setListener(listsner: listener)

            let schedule = InAppMessage.schedule(
                time: InAppMessageSchedule.Time(
                    startedAt: Date(timeIntervalSince1970: 1.001),
                    deliverAt: Date(timeIntervalSince1970: 2.0)
                )
            )
            let delay = InAppMessageDelay(
                schedule: schedule,
                requestedAt: Date(timeIntervalSince1970: 1.95)
            )

            let task = sut.schedule(delay: delay)

            expect(task.isCompleted) == false
            verify(exactly: 0) {
                listener.onScheduleMock
            }

            Thread.sleep(forTimeInterval: 0.2)

            expect(task.isCompleted) == true
            verify(exactly: 1) {
                listener.onScheduleMock
            }
        }

        it("task cancel") {
            let sut = DefaultInAppMessageDelayScheduler(clock: SystemClock.shared, scheduler: Schedulers.dispatch())
            let listener = MockInAppMessageScheduleListener()
            sut.setListener(listsner: listener)

            let schedule = InAppMessage.schedule(
                time: InAppMessageSchedule.Time(
                    startedAt: Date(timeIntervalSince1970: 1.001),
                    deliverAt: Date(timeIntervalSince1970: 2.0)
                )
            )
            let delay = InAppMessageDelay(
                schedule: schedule,
                requestedAt: Date(timeIntervalSince1970: 1.95)
            )

            let task = sut.schedule(delay: delay)
            expect(task.isCompleted) == false
            verify(exactly: 0) {
                listener.onScheduleMock
            }

            task.cancel()

            expect(task.isCompleted) == true
            verify(exactly: 0) {
                listener.onScheduleMock
            }

            Thread.sleep(forTimeInterval: 0.2)
            verify(exactly: 0) {
                listener.onScheduleMock
            }
        }
    }
}
