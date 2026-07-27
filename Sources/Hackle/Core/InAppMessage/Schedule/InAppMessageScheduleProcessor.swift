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
    // android는 trigger는 coreExecutor, delay는 별도 단일 스레드 executor로 처리해 각 경로 내부만 FIFO이고
    // 두 경로 사이는 서로 직렬화되지 않는다(HackleApps.kt). iOS는 두 진입점을 하나의 FIFO 큐로 합류시켜
    // 정답지보다 더 강한 보장(전체 직렬화)을 의도적으로 제공한다 — android delta 이식 시 동등하다고 오인하지 말 것.
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
