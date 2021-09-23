//
// Created by yong on 2020/12/20.
//

import Foundation

protocol Scheduler {
    func schedulePeriodically(delay: TimeInterval, period: TimeInterval, task: @escaping () -> ()) -> ScheduledJob
}

protocol ScheduledJob {
    func cancel()
}

class DispatchSourceTimerScheduler: Scheduler {
    func schedulePeriodically(delay: TimeInterval, period: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
        let queue = DispatchQueue(label: "io.hackle.DispatchSourceTimerScheduler")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + delay, repeating: period)
        timer.setEventHandler {
            task()
        }
        timer.resume()
        return Job(timer: timer)
    }

    class Job: ScheduledJob {

        private var timer: DispatchSourceTimer?

        init(timer: DispatchSourceTimer) {
            self.timer = timer
        }

        func cancel() {
            timer?.cancel()
            timer = nil
        }
    }
}
