import Foundation

class InAppMessageDelay {
    let schedule: InAppMessageSchedule
    let requestedAt: Date

    init(schedule: InAppMessageSchedule, requestedAt: Date) {
        self.schedule = schedule
        self.requestedAt = requestedAt
    }
}

extension InAppMessageDelay: CustomStringConvertible {
    var description: String {
        "InAppMessageDelay(schedule: \(schedule), requestedAt: \(requestedAt))"
    }

    var delay: TimeInterval {
        return schedule.time.deliverAt.timeIntervalSince(requestedAt)
    }

    static func from(request: InAppMessageScheduleRequest) -> InAppMessageDelay {
        return InAppMessageDelay(schedule: request.schedule, requestedAt: request.requestedAt)
    }
}
