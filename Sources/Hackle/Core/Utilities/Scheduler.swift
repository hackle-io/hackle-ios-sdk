import Foundation

protocol Scheduler {
    func schedule(delay: TimeInterval, task: @escaping () -> ()) -> ScheduledJob
    func schedulePeriodically(delay: TimeInterval, period: TimeInterval, task: @escaping () -> ()) -> ScheduledJob
}

protocol ScheduledJob {
    func cancel()
}

enum Schedulers {
    static func dispatch(queue: DispatchQueue = DispatchQueue(label: "io.hackle.DispatchSourceTimerScheduler")) -> Scheduler {
        DispatchSourceTimerScheduler(queue: queue)
    }
}

class DispatchSourceTimerScheduler: Scheduler {

    private let queue: DispatchQueue

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func schedule(delay: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
        let timer = DispatchSource.makeTimerSource(queue: queue)

        timer.schedule(deadline: .now() + delay, repeating: .never)
        timer.setEventHandler {
            task()
        }
        timer.resume()
        return Job(timer: timer)
    }

    func schedulePeriodically(delay: TimeInterval, period: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
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
