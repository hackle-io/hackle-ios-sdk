import Foundation

class InAppMessageSchedule {

    let dispatchId: String
    let inAppMessageKey: InAppMessage.Key
    let identifiers: Identifiers
    let time: Time
    let evaluation: InAppMessageEvaluation
    let eventBasedContext: EventBasedContext

    init(
        dispatchId: String,
        inAppMessageKey: InAppMessage.Key,
        identifiers: Identifiers,
        time: Time,
        evaluation: InAppMessageEvaluation,
        eventBasedContext: EventBasedContext
    ) {
        self.dispatchId = dispatchId
        self.inAppMessageKey = inAppMessageKey
        self.identifiers = identifiers
        self.time = time
        self.evaluation = evaluation
        self.eventBasedContext = eventBasedContext
    }

    class Time {
        let startedAt: Date
        let deliverAt: Date

        init(startedAt: Date, deliverAt: Date) {
            self.startedAt = startedAt
            self.deliverAt = deliverAt
        }

        func delay(at: Date) -> TimeInterval {
            return deliverAt.timeIntervalSince(at)
        }
    }

    class EventBasedContext {
        let insertId: String
        let event: Event

        init(insertId: String, event: Event) {
            self.insertId = insertId
            self.event = event
        }
    }
}

extension InAppMessageSchedule: CustomStringConvertible {
    var description: String {
        "InAppMessageSchedule(dispatchId: \(dispatchId), inAppMessageKey: \(inAppMessageKey), identifiers: \(identifiers), time: \(time), evaluation: \(evaluation), eventBasedContext: \(eventBasedContext))"
    }

    func toRequest(type: InAppMessageScheduleType, requestedAt: Date) -> InAppMessageScheduleRequest {
        return InAppMessageScheduleRequest(schedule: self, scheduleType: type, requestedAt: requestedAt)
    }
}

extension InAppMessageSchedule.Time: CustomStringConvertible {
    var description: String {
        "Time(startedAt: \(startedAt), deliverAt: \(deliverAt))"
    }
}

extension InAppMessageSchedule.EventBasedContext: CustomStringConvertible {
    var description: String {
        "EventBasedContext(insertId: \(insertId), event: \(event.key))"
    }
}
