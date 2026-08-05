import Foundation

class DelayedInAppMessageScheduler: InAppMessageScheduler {

    private let deliverProcessor: InAppMessageDeliverProcessor
    private let delayManager: InAppMessageDelayManager

    init(deliverProcessor: InAppMessageDeliverProcessor, delayManager: InAppMessageDelayManager) {
        self.deliverProcessor = deliverProcessor
        self.delayManager = delayManager
    }

    func support(scheduleType: InAppMessageScheduleType) -> Bool {
        return scheduleType == .delayed
    }

    func deliver(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse {
        guard delayManager.delete(request: request) != nil else {
            throw HackleError.error("InAppMessageDelay not found (inAppMessageKey: \(request.schedule.inAppMessageKey))")
        }

        let deliverRequest = InAppMessageDeliverRequest.of(request: request)
        let deliverResponse = await deliverProcessor.process(request: deliverRequest)
        return InAppMessageScheduleResponse.of(request: request, code: .deliver, deliverResponse: deliverResponse)
    }

    func delay(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse {
        let delay = delayManager.delay(request: request)
        return InAppMessageScheduleResponse.of(request: request, code: .delay, delay: delay)
    }

    func ignore(request: InAppMessageScheduleRequest) async throws -> InAppMessageScheduleResponse {
        let delay = delayManager.delete(request: request)
        return InAppMessageScheduleResponse.of(request: request, code: .ignore, delay: delay)
    }
}
