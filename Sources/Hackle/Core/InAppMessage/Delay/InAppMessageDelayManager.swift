import Foundation

protocol InAppMessageDelayManager {
    func registerAndDelay(request: InAppMessageScheduleRequest) throws -> InAppMessageDelay

    func delay(request: InAppMessageScheduleRequest) throws -> InAppMessageDelay

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

    func registerAndDelay(request: InAppMessageScheduleRequest) throws -> InAppMessageDelay {
        // App SDK only delays without register
        return try delay(request: request)
    }

    func delay(request: InAppMessageScheduleRequest) throws -> InAppMessageDelay {
        try ensureDelay(request: request)

        let delay = InAppMessageDelay.from(request: request)
        let task = scheduler.schedule(delay: delay)
        lock.write {
            tasks[delay.schedule.dispatchId] = task
        }

        Log.debug("InAppMessage Delay started. \(delay)")
        return delay
    }

    private func ensureDelay(request: InAppMessageScheduleRequest) throws {
        try lock.write {
            guard let existing = tasks[request.schedule.dispatchId] else {
                return
            }
            guard existing.isCompleted else {
                throw HackleError.error("Existing delay is not completed: \(request)")
            }
            tasks.removeValue(forKey: request.schedule.dispatchId)
        }
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
