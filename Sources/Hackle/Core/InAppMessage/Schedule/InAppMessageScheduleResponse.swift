import Foundation

class InAppMessageScheduleResponse {
    let dispatchId: String
    let inAppMesasgeKey: InAppMessage.Key
    let code: Code
    let deliverResponse: InAppMessageDeliverResponse?
    let delay: InAppMessageDelay?

    init(
        dispatchId: String,
        inAppMesasgeKey: InAppMessage.Key,
        code: Code,
        deliverResponse: InAppMessageDeliverResponse?,
        delay: InAppMessageDelay?
    ) {
        self.dispatchId = dispatchId
        self.inAppMesasgeKey = inAppMesasgeKey
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
        "InAppMessageScheduleResponse(dispatchId: \(dispatchId), inAppMesasgeKey: \(inAppMesasgeKey), code: \(code))"
    }

    static func of(
        request: InAppMessageScheduleRequest,
        code: Code,
        deliverReponse: InAppMessageDeliverResponse? = nil,
        delay: InAppMessageDelay? = nil
    ) -> InAppMessageScheduleResponse {
        return InAppMessageScheduleResponse(
            dispatchId: request.schedule.dispatchId,
            inAppMesasgeKey: request.schedule.inAppMessageKey,
            code: code,
            deliverResponse: deliverReponse,
            delay: delay
        )
    }
}
