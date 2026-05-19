import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle


class PushMetricRegistrySpecs: QuickSpec {
    override class func spec() {

        class SchedulerStub: Scheduler {

            var jobs = [Job]()
            var scheduledCount: Int {
                jobs.count
            }

            func schedule(delay: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
                fatalError("schedule(delay:task:) has not been implemented")
            }

            func schedulePeriodically(delay: TimeInterval, period: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
                let job = Job()
                jobs.append(job)
                return job
            }

            class Job: ScheduledJob {
                var isCompleted: Bool = false
                var isCanceled: Bool = false

                func cancel() {
                    isCanceled = true
                    isCompleted = true
                }
            }
        }

        describe("start") {

            it("scheduling") {
                let scheduler = SchedulerStub()
                let registry = PushMetricRegistry(scheduler: scheduler, pushInterval: 10)

                registry.start()

                expect(scheduler.scheduledCount).toEventually(equal(1))
            }

            it("schedule only once") {
                let scheduler = SchedulerStub()
                let registry = PushMetricRegistry(scheduler: scheduler, pushInterval: 10)

                registry.start()
                registry.start()
                registry.start()
                registry.start()

                expect(scheduler.scheduledCount).toEventually(equal(1))
                // 추가로 N번 더 dispatch했어도 1로 유지되는지 잠깐 더 본다.
                expect(scheduler.scheduledCount).toNotEventually(beGreaterThan(1))
            }
        }

        describe("stop") {
            it("cancel scheduling") {
                let scheduler = SchedulerStub()
                let registry = PushMetricRegistry(scheduler: scheduler, pushInterval: 10)

                registry.start()
                registry.stop()

                expect(scheduler.jobs.first?.isCanceled).toEventually(equal(true))
            }

            it("publish") {

                class Stub: PushMetricRegistry, @unchecked Sendable {
                    var publishCount = 0

                    override func publish() {
                        publishCount = publishCount + 1
                    }
                }

                let registry = Stub(scheduler: SchedulerStub(), pushInterval: 60)

                registry.start()
                registry.stop()

                expect(registry.publishCount).toEventually(equal(1))
            }
        }
    }
}
