import Foundation

class InAppMessageScheduleResponse: @unchecked Sendable {
    let dispatchId: String
    let inAppMessageKey: InAppMessage.Key
    let code: Code
    let deliverResponse: InAppMessageDeliverResponse?
    let delay: InAppMessageDelay?

    init(
        dispatchId: String,
        inAppMessageKey: InAppMessage.Key,
        code: Code,
        deliverResponse: InAppMessageDeliverResponse?,
        delay: InAppMessageDelay?
    ) {
        self.dispatchId = dispatchId
        self.inAppMessageKey = inAppMessageKey
        self.code = code
        self.deliverResponse = deliverResponse
        self.delay = delay
    }

    enum Code {
        case deliver
        case delay
        case ignore
        case exception
    }
}

extension InAppMessageScheduleResponse: CustomStringConvertible {
    var description: String {
        "InAppMessageScheduleResponse(dispatchId: \(dispatchId), inAppMessageKey: \(inAppMessageKey), code: \(code))"
    }

    static func of(
        request: InAppMessageScheduleRequest,
        code: Code,
        deliverResponse: InAppMessageDeliverResponse? = nil,
        delay: InAppMessageDelay? = nil
    ) -> InAppMessageScheduleResponse {
        return InAppMessageScheduleResponse(
            dispatchId: request.schedule.dispatchId,
            inAppMessageKey: request.schedule.inAppMessageKey,
            code: code,
            deliverResponse: deliverResponse,
            delay: delay
        )
    }
}
