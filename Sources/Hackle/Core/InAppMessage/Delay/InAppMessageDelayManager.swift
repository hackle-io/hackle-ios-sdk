import Foundation

protocol InAppMessageDelayManager {
    func registerAndDelay(request: InAppMessageScheduleRequest) -> InAppMessageDelay

    func delay(request: InAppMessageScheduleRequest) -> InAppMessageDelay

    func delete(request: InAppMessageScheduleRequest) -> InAppMessageDelay?

    func cancelAll() -> [InAppMessageDelay]
}

class DefaultInAppMessageDelayManager: InAppMessageDelayManager {

    private let lock = ReadWriteLock(label: "io.hackle.DefaultInAppMessageDelayManager.Lock")

    private let scheduler: InAppMessageDelayScheduler
    private var tasks: [String: InAppMessageDelayTask]

    init(scheduler: InAppMessageDelayScheduler) {
        self.scheduler = scheduler
        self.tasks = [:]
    }

    func registerAndDelay(request: InAppMessageScheduleRequest) -> InAppMessageDelay {
        // App SDK only delays without register
        return delay(request: request)
    }

    func delay(request: InAppMessageScheduleRequest) -> InAppMessageDelay {
        let delay = InAppMessageDelay.from(request: request)
        let task = scheduler.schedule(delay: delay)
        lock.write {
            tasks[delay.schedule.dispatchId] = task
        }

        Log.debug("InAppMessage Delay started. \(delay)")
        return delay
    }

    func delete(request: InAppMessageScheduleRequest) -> InAppMessageDelay? {
        let task = lock.write {
            tasks.removeValue(forKey: request.schedule.dispatchId)
        }
        if let delay = task?.delay {
            Log.debug("InAppMessage Delay removed. dispatchId: \(request.schedule.dispatchId)")
            return delay
        }
        return nil
    }

    func cancelAll() -> [InAppMessageDelay] {
        let snapshot = lock.write {
            let items = Array(tasks.values)
            tasks.removeAll()
            return items
        }
        for task in snapshot {
            task.cancel()
        }
        return snapshot.map { it in
            it.delay
        }
    }
}
