import Foundation

protocol InAppMessageTriggerHandler {
    func handle(trigger: InAppMessageTrigger) throws
}

class DefaultInAppMessageTriggerHandler: InAppMessageTriggerHandler, @unchecked Sendable {
    private let scheduleProcessor: InAppMessageScheduleProcessor

    init(scheduleProcessor: InAppMessageScheduleProcessor) {
        self.scheduleProcessor = scheduleProcessor
    }

    func handle(trigger: InAppMessageTrigger) throws {
        let schedule = try InAppMessageSchedule.create(trigger: trigger)
        let scheduleRequest = schedule.toRequest(type: .triggered, requestedAt: trigger.event.timestamp)
        Task {
            await self.scheduleProcessor.process(request: scheduleRequest)
        }
    }
}
