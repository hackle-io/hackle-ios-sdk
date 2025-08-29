import Foundation

class InAppMessageDeliverResponse {

    let dispatchId: String
    let inAppMessageKey: InAppMessage.Key
    let code: Code
    let presentResponse: InAppMessagePresentResponse?

    init(
        dispatchId: String,
        inAppMessageKey: InAppMessage.Key,
        code: InAppMessageDeliverResponse.Code,
        presentResponse: InAppMessagePresentResponse?
    ) {
        self.dispatchId = dispatchId
        self.inAppMessageKey = inAppMessageKey
        self.code = code
        self.presentResponse = presentResponse
    }

    enum Code {
        case present
        case workspaceNotFound
        case inAppMessageNotFound
        case identifierChanged
        case ineligible
        case exception
    }
}

extension InAppMessageDeliverResponse: CustomStringConvertible {
    var description: String {
        "InAppMessageDeliverResponse(dispatchId: \(dispatchId), inAppMessageKey: \(inAppMessageKey), code: \(code))"
    }

    static func of(
        request: InAppMessageDeliverRequest,
        code: Code,
        presentResponse: InAppMessagePresentResponse? = nil
    ) -> InAppMessageDeliverResponse {
        return InAppMessageDeliverResponse(
            dispatchId: request.dispatchId,
            inAppMessageKey: request.inAppMessageKey,
            code: code,
            presentResponse: presentResponse
        )
    }
}
