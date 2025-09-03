import Foundation

protocol InAppMessageSchedulerFactory {
    func get(scheduleType: InAppMessageScheduleType) throws -> InAppMessageScheduler
}

class DefaultInAppMessageSchedulerFactory: InAppMessageSchedulerFactory {

    private let schedulers: [InAppMessageScheduler]

    init(schedulers: [InAppMessageScheduler]) {
        self.schedulers = schedulers
    }

    func get(scheduleType: InAppMessageScheduleType) throws -> InAppMessageScheduler {
        guard let scheduler = schedulers.first(where: { it in it.support(scheduleType: scheduleType) }) else {
            throw HackleError.error("Unsupported InAppMessageScheduleType [\(scheduleType)]")
        }
        return scheduler
    }
}
