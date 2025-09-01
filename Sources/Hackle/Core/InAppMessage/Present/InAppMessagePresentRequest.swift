import Foundation

class InAppMessagePresentRequest {

    let dispatchId: String
    let inAppMessage: InAppMessage
    let message: InAppMessage.Message
    let user: HackleUser
    let requestedAt: Date
    let reason: String
    let properties: [String: Any]

    init(
        dispatchId: String,
        inAppMessage: InAppMessage,
        message: InAppMessage.Message,
        user: HackleUser,
        requestedAt: Date,
        reason: String,
        properties: [String: Any]
    ) {
        self.dispatchId = dispatchId
        self.inAppMessage = inAppMessage
        self.message = message
        self.user = user
        self.requestedAt = requestedAt
        self.reason = reason
        self.properties = properties
    }
}

extension InAppMessagePresentRequest: CustomStringConvertible {
    var description: String {
        "InAppMessagePresentRequest(dispatchId: \(dispatchId), inAppMessage: \(inAppMessage), message: \(message.layout.displayType), user: \(user.identifiers), requestedAt: \(requestedAt), reason: \(reason), properties: \(properties))"
    }

    static func of(
        request: InAppMessageDeliverRequest,
        inAppMessage: InAppMessage,
        user: HackleUser,
        eligibilityEvaluation: InAppMessageEligibilityEvaluation,
        layoutEvaluation: InAppMessageLayoutEvaluation
    ) -> InAppMessagePresentRequest {
        return InAppMessagePresentRequest(
            dispatchId: request.dispatchId,
            inAppMessage: inAppMessage,
            message: layoutEvaluation.message,
            user: user,
            requestedAt: request.requestedAt,
            reason: eligibilityEvaluation.reason,
            properties: PropertiesBuilder().add(request.properties).add(layoutEvaluation.properties).build()
        )
    }
}
