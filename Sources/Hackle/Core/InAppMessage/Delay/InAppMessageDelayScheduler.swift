import Foundation

protocol InAppMessageDelayScheduler {
    func schedule(delay: InAppMessageDelay) -> InAppMessageDelayTask
}

class DefaultInAppMessageDelayScheduler: InAppMessageDelayScheduler {

    private let clock: Clock
    private let scheduler: Scheduler

    private var listsner: InAppMessageScheduleListener? = nil

    init(clock: Clock, scheduler: Scheduler) {
        self.clock = clock
        self.scheduler = scheduler
    }

    func setListener(listsner: InAppMessageScheduleListener) {
        self.listsner = listsner
    }

    func schedule(delay: InAppMessageDelay) -> InAppMessageDelayTask {
        let job = scheduler.schedule(delay: delay.delay) { [weak self] in
            guard let self = self else {
                return
            }
            self.command(delay: delay)
        }
        return ScheduledInAppMessageDelayTask(delay: delay, job: job)
    }

    private func command(delay: InAppMessageDelay) {
        let now = clock.now()
        let request = delay.schedule.toRequest(type: .delayed, requestedAt: now)
        listsner?.onSchedule(request: request)
    }

    class ScheduledInAppMessageDelayTask: InAppMessageDelayTask {

        let delay: InAppMessageDelay
        private let job: ScheduledJob

        init(delay: InAppMessageDelay, job: ScheduledJob) {
            self.delay = delay
            self.job = job
        }

        var isCompleted: Bool {
            job.isCompleted
        }

        func cancel() {
            job.cancel()
            Log.debug("InAppMessage Delay canclled: \(delay)")
        }
    }
}
