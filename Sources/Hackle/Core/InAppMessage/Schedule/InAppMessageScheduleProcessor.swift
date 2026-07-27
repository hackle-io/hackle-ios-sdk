import Foundation

protocol InAppMessageScheduleProcessor {
    @discardableResult
    func process(request: InAppMessageScheduleRequest) async -> InAppMessageScheduleResponse
    func processAsync(request: InAppMessageScheduleRequest)
}

class DefaultInAppMessageScheduleProcessor: InAppMessageScheduleProcessor, InAppMessageScheduleListener, @unchecked Sendable {

    private let actionDeterminer: InAppMessageScheduleActionDeterminer
    private let schedulerFactory: InAppMessageSchedulerFactory
    private let processQueue = SerialTaskQueue()

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

    // trigger·delay 콜백의 fire-and-forget 진입점.
    // 제출 순서(FIFO)를 보존해 "먼저 발생한 이벤트의 IAM이 우선"하는 직렬 실행 순서를 유지한다.
    func processAsync(request: InAppMessageScheduleRequest) {
        processQueue.enqueue { [weak self] in
            guard let self else { return }
            await self.process(request: request)
        }
    }

    // InAppMessageScheduleListener의 delay 타이머 콜백
    func onSchedule(request: InAppMessageScheduleRequest) {
        processAsync(request: request)
    }
}
