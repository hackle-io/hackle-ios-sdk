import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle


class PushMetricRegistrySpecs: QuickSpec {
    override func spec() {

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

                expect(scheduler.scheduledCount) == 1
            }

            it("schedule only once") {
                let scheduler = SchedulerStub()
                let registry = PushMetricRegistry(scheduler: scheduler, pushInterval: 10)

                registry.start()
                registry.start()
                registry.start()
                registry.start()

                expect(scheduler.scheduledCount) == 1
            }
        }

        describe("stop") {
            it("cancel scheduling") {
                let scheduler = SchedulerStub()
                let registry = PushMetricRegistry(scheduler: scheduler, pushInterval: 10)

                registry.start()
                registry.stop()

                expect(scheduler.jobs[0].isCanceled) == true
            }

            it("publish") {

                class Stub: PushMetricRegistry {
                    var publishCount = 0

                    override func publish() {
                        publishCount = publishCount + 1
                    }
                }

                let registry = Stub(scheduler: SchedulerStub(), pushInterval: 60)

                registry.start()
                registry.stop()

                expect(registry.publishCount) == 1
            }
        }
    }
}