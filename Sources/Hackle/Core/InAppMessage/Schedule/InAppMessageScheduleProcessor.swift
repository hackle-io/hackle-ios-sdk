import Foundation

protocol InAppMessageScheduleProcessor {
    @discardableResult
    func process(request: InAppMessageScheduleRequest) async -> InAppMessageScheduleResponse
}

class DefaultInAppMessageScheduleProcessor: InAppMessageScheduleProcessor, InAppMessageScheduleListener, @unchecked Sendable {

    private let actionDeterminer: InAppMessageScheduleActionDeterminer
    private let schedulerFactory: InAppMessageSchedulerFactory

    init(actionDeterminer: InAppMessageScheduleActionDeterminer, schedulerFactory: InAppMessageSchedulerFactory) {
        self.actionDeterminer = actionDeterminer
        self.schedulerFactory = schedulerFactory
    }

    @discardableResult
    func process(request: InAppMessageScheduleRequest) async -> InAppMessageScheduleResponse {
        Log.debug("InAppMessage Schedule Request: \(request)")

        do {
            let response = try await schedule(request: request)
            Log.debug("InAppMessage Schedule Response: \(response)")
            return response
        } catch {
            Log.error("Failed to process InAppMessageSchedule: \(error)")
            return InAppMessageScheduleResponse.of(request: request, code: .exception)
        }
    }

    private func schedule(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse {
        let action = try actionDeterminer.determine(request: request)
        let scheduler = try schedulerFactory.get(scheduleType: request.scheduleType)
        return try await scheduler.schedule(action: action, request: request)
    }

    // InAppMessageScheduleListener의 delay 타이머 콜백
    func onSchedule(request: InAppMessageScheduleRequest) {
        Task {
            await self.process(request: request)
        }
    }
}
