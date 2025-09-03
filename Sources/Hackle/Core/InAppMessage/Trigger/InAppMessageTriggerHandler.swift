import Foundation

protocol InAppMessageTriggerHandler {
    func handle(trigger: InAppMessageTrigger)
}

class DefaultInAppMessageTriggerHandler: InAppMessageTriggerHandler {
    private let scheduleProcessor: InAppMessageScheduleProcessor

    init(scheduleProcessor: InAppMessageScheduleProcessor) {
        self.scheduleProcessor = scheduleProcessor
    }

    func handle(trigger: InAppMessageTrigger) {
        let schedule = InAppMessageSchedule.create(trigger: trigger)
        let scheduleRequest = schedule.toRequest(type: .triggered, requestedAt: trigger.event.timestamp)
        scheduleProcessor.process(request: scheduleRequest)
    }
}
