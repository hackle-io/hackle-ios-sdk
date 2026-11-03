import Foundation
import Nimble
import Quick
@testable import Hackle

class PollingSynchronizerSpecs: AsyncSpec {
    override class func spec() {

        describe("sync") {
            it("delegate") {
                // given
                let delegate = MockSynchronizer()
                let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: 10)

                // when
                await awaitCompletion { try await sut.sync() }

                // then
                verify(exactly: 1) {
                    delegate.syncMock
                }
            }
        }

        describe("start") {
            it("no polling") {
                // given
                let delegate = MockSynchronizer()
                let scheduler = MockScheduler()
                let sut = PollingSynchronizer(delegate: delegate, scheduler: scheduler, interval: -1)

                // when
                sut.start()

                // then
                verify(exactly: 0) {
                    scheduler.schedulePeriodicallyMock
                }
            }

            it("start scheduling") {
                // given
                let delegate = MockSynchronizer()
                let scheduler = MockScheduler()
                every(scheduler.schedulePeriodicallyMock).returns(MockScheduledJob())
                let sut = PollingSynchronizer(delegate: delegate, scheduler: scheduler, interval: 0.1)

                // when
                sut.start()

                // then
                verify(exactly: 1) {
                    scheduler.schedulePeriodicallyMock
                }
                let (delay, period, task) = scheduler.schedulePeriodicallyMock.firstInvokation().arguments
                expect(delay) == 0.1
                expect(period) == 0.1

                task()
                await expect(delegate.syncMock.invokations().count).toEventually(equal(1), timeout: .seconds(5))
            }

            it("start once") {
                // given
                let delegate = MockSynchronizer()
                let scheduler = MockScheduler()
                every(scheduler.schedulePeriodicallyMock).returns(MockScheduledJob())
                let sut = PollingSynchronizer(delegate: delegate, scheduler: scheduler, interval: 0.1)

                // when
                let q = DispatchQueue(label: "test")
                for _ in 0..<10 {
                    q.async {
                        sut.start()
                    }
                }
                q.sync {}

                // then
                verify(exactly: 1) {
                    scheduler.schedulePeriodicallyMock
                }
            }
        }

        describe("stop") {
            it("no polling") {
                // given
                let delegate = MockSynchronizer()
                let sut = PollingSynchronizer(delegate: delegate, scheduler: Schedulers.dispatch(), interval: -1)

                // when
                sut.start()
                sut.stop()
            }

            it("cancel polling job") {
                // given
                let delegate = MockSynchronizer()
                let scheduler = MockScheduler()
                let job = MockScheduledJob()
                every(scheduler.schedulePeriodicallyMock).returns(job)
                let sut = PollingSynchronizer(delegate: delegate, scheduler: scheduler, interval: 0.1)

                // when
                sut.start()
                sut.stop()

                // then
                verify(exactly: 1) {
                    job.cancelMock
                }
            }
        }

        it("onChanged") {
            let delegate = MockSynchronizer()
            let scheduler = MockScheduler()
            let job = MockScheduledJob()
            every(scheduler.schedulePeriodicallyMock).returns(job)
            let sut = PollingSynchronizer(delegate: delegate, scheduler: scheduler, interval: 0.5)

            sut.onForeground(nil, timestamp: Date(), isFromBackground: true)
            verify(exactly: 1) {
                scheduler.schedulePeriodicallyMock
            }
            verify(exactly: 0) {
                job.cancelMock
            }

            sut.onBackground(nil, timestamp: Date())
            verify(exactly: 1) {
                job.cancelMock
            }
        }
    }
}
