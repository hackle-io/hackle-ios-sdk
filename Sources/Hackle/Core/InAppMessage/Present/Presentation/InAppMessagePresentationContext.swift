import Foundation

final class InAppMessagePresentationContext: @unchecked Sendable {
    let dispatchId: String
    let inAppMessage: InAppMessage
    let message: InAppMessage.Message
    let user: HackleUser
    let decisionReason: String
    let properties: [String: Any]
    let triggerEvent: Event

    init(
        dispatchId: String,
        inAppMessage: InAppMessage,
        message: InAppMessage.Message,
        user: HackleUser,
        decisionReason: String,
        properties: [String: Any],
        triggerEvent: Event
    ) {
        self.dispatchId = dispatchId
        self.inAppMessage = inAppMessage
        self.message = message
        self.user = user
        self.decisionReason = decisionReason
        self.properties = properties
        self.triggerEvent = triggerEvent
    }
}

extension InAppMessagePresentationContext: CustomStringConvertible {
    var description: String {
        "InAppMessagePresentationContext(dispatchId: \(dispatchId), inAppMessage: \(inAppMessage), layout: \(message.layout.displayType))"
    }

    static func of(request: InAppMessagePresentRequest) -> InAppMessagePresentationContext {
        return InAppMessagePresentationContext(
            dispatchId: request.dispatchId,
            inAppMessage: request.inAppMessage,
            message: request.message,
            user: request.user,
            decisionReason: request.reason,
            properties: request.properties,
            triggerEvent: request.triggerEvent
        )
    }
}
