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

    func deliver(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        guard let delay = delayManager.delete(request: request) else {
            throw HackleError.error("InAppMessageDelay not found (inAppMessageKey: \(request.schedule.inAppMessageKey))")
        }

        let deliverRequest = InAppMessageDeliverRequest.of(request: request)
        let deliverResponse = deliverProcessor.process(request: deliverRequest)
        return InAppMessageScheduleResponse.of(request: request, code: .deliver, deliverReponse: deliverResponse)
    }

    func delay(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        let delay = try delayManager.delay(request: request)
        return InAppMessageScheduleResponse.of(request: request, code: .delay, delay: delay)
    }

    func ignore(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        let delay = delayManager.delete(request: request)
        return InAppMessageScheduleResponse.of(request: request, code: .ignore, delay: delay)
    }
}
