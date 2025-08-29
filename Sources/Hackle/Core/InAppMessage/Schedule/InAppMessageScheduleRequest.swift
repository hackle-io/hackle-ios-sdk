import Foundation

class InAppMessageScheduleRequest {

    let schedule: InAppMessageSchedule
    let scheduleType: InAppMessageScheduleType
    let requestedAt: Date

    init(
        schedule: InAppMessageSchedule,
        scheduleType: InAppMessageScheduleType,
        requestedAt: Date
    ) {
        self.schedule = schedule
        self.scheduleType = scheduleType
        self.requestedAt = requestedAt
    }
}

extension InAppMessageScheduleRequest: CustomStringConvertible {
    var description: String {
        "InAppMessageScheduleRequest(schedule: \(schedule), scheduleType: \(scheduleType), requestedAt: \(requestedAt))"
    }
    var delay: TimeInterval {
        return schedule.time.deliverAt.timeIntervalSince(requestedAt)
    }
}
