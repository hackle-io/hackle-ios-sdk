import Foundation

protocol InAppMessageTriggerHandler {
    func handle(trigger: InAppMessageTrigger)
}

class DefaultInAppMessageTriggerHandler: InAppMessageTriggerHandler, @unchecked Sendable {
    private let scheduleProcessor: InAppMessageScheduleProcessor

    init(scheduleProcessor: InAppMessageScheduleProcessor) {
        self.scheduleProcessor = scheduleProcessor
    }

    // P9 Task 진입 경계 ① — trigger handler(eventQueue)
    func handle(trigger: InAppMessageTrigger) {
        let schedule = InAppMessageSchedule.create(trigger: trigger)
        let scheduleRequest = schedule.toRequest(type: .triggered, requestedAt: trigger.event.timestamp)
        Task {
            await self.scheduleProcessor.process(request: scheduleRequest)
        }
    }
}
