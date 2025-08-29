//
// Created by yong on 2020/12/20.
//

import Foundation

protocol Scheduler {
    func schedule(delay: TimeInterval, task: @escaping () -> ()) -> ScheduledJob
    func schedulePeriodically(delay: TimeInterval, period: TimeInterval, task: @escaping () -> ()) -> ScheduledJob
}

protocol ScheduledJob {
    var isCompleted: Bool { get }
    func cancel()
}

enum Schedulers {
    static func dispatch() -> Scheduler {
        DispatchSourceTimerScheduler()
    }
}

class DispatchSourceTimerScheduler: Scheduler {
    func schedule(delay: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
        let queue = DispatchQueue(label: "io.hackle.DispatchSourceTimerScheduler")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        let job = Job(timer: timer)

        timer.schedule(deadline: .now() + delay, repeating: .never)
        timer.setEventHandler { [weak job] in
            task()
            job?.complete()
        }
        timer.resume()
        return job
    }

    func schedulePeriodically(delay: TimeInterval, period: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
        let queue = DispatchQueue(label: "io.hackle.DispatchSourceTimerScheduler")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        let job = Job(timer: timer)

        timer.schedule(deadline: .now() + delay, repeating: period)
        timer.setEventHandler {
            task()
        }
        timer.resume()
        return job
    }

    class Job: ScheduledJob {

        private var timer: DispatchSourceTimer?

        init(timer: DispatchSourceTimer) {
            self.timer = timer
        }

        deinit {
            timer?.cancel()
            timer = nil
        }

        var isCompleted: Bool {
            return timer == nil
        }

        func complete() {
            timer?.cancel()
            timer = nil
        }

        func cancel() {
            timer?.cancel()
            timer = nil
        }
    }
}
