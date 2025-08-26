import Foundation

protocol InAppMessageScheduleProcessor {
    func process(request: InAppMessageScheduleRequest) -> InAppMessageScheduleResponse
}

class DefaultInAppMessageScheduleProcessor: InAppMessageScheduleProcessor, InAppMessageScheduleListener {

    private let actionDeterminer: InAppMessageScheduleActionDeterminer
    private let schedulerFactory: InAppMessageSchedulerFactory

    init(actionDeterminer: InAppMessageScheduleActionDeterminer, schedulerFactory: InAppMessageSchedulerFactory) {
        self.actionDeterminer = actionDeterminer
        self.schedulerFactory = schedulerFactory
    }

    func process(request: InAppMessageScheduleRequest) -> InAppMessageScheduleResponse {
        Log.debug("InAppMessage Schedule Request: \(request)")

        do {
            let response = try schedule(request: request)
            Log.debug("InAppMessage Schedule Response: \(response)")
            return response
        } catch {
            Log.error("Failed to process InAppMessageSchedule: \(error)")
            return InAppMessageScheduleResponse.of(request: request, code: .exception)
        }
    }

    private func schedule(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        let action = try actionDeterminer.determine(request: request)
        let scheduler = try schedulerFactory.get(scheduleType: request.scheduleType)
        return try scheduler.schedule(action: action, request: request)
    }

    func onSchedule(request: InAppMessageScheduleRequest) {
        process(request: request)
    }
}
