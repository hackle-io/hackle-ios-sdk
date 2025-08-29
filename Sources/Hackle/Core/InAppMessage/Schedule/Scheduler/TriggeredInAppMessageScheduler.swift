import Foundation

class TriggeredInAppMessageScheduler: InAppMessageScheduler {

    private let deliverProcessor: InAppMessageDeliverProcessor
    private let delayManager: InAppMessageDelayManager

    init(deliverProcessor: InAppMessageDeliverProcessor, delayManager: InAppMessageDelayManager) {
        self.deliverProcessor = deliverProcessor
        self.delayManager = delayManager
    }

    func support(scheduleType: InAppMessageScheduleType) -> Bool {
        return scheduleType == .triggered
    }

    func deliver(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        let deliverRequest = InAppMessageDeliverRequest.of(request: request)
        let deliverResponse = deliverProcessor.process(request: deliverRequest)
        return InAppMessageScheduleResponse.of(request: request, code: .deliver, deliverReponse: deliverResponse)
    }

    func delay(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        let delay = try delayManager.registerAndDelay(request: request)
        return InAppMessageScheduleResponse.of(request: request, code: .delay, delay: delay)
    }

    func ignore(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleResponse {
        return InAppMessageScheduleResponse.of(request: request, code: .ignore)
    }
}
