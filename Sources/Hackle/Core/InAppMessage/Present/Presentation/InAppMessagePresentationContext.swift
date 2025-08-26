import Foundation

class InAppMessagePresentationContext {

    let dispatchId: String
    let inAppMessage: InAppMessage
    let message: InAppMessage.Message
    let user: HackleUser
    let decisionReasion: String
    let properties: [String: Any]

    init(
        dispatchId: String,
        inAppMessage: InAppMessage,
        message: InAppMessage.Message,
        user: HackleUser,
        decisionReasion: String,
        properties: [String: Any]
    ) {
        self.dispatchId = dispatchId
        self.inAppMessage = inAppMessage
        self.message = message
        self.user = user
        self.decisionReasion = decisionReasion
        self.properties = properties
    }
}

extension InAppMessagePresentationContext: CustomStringConvertible {

    var description: String {
        "InAppMessagePresentationContext(dispatchId: \(dispatchId), inAppMessage: \(inAppMessage), layout: \(message.layout.displayType))"
    }

    static func of(
        request: InAppMessagePresentRequest,
        evaluation: InAppMessageLayoutEvaluation
    ) -> InAppMessagePresentationContext {
        return InAppMessagePresentationContext(
            dispatchId: request.dispatchId,
            inAppMessage: evaluation.inAppMessage,
            message: evaluation.message,
            user: request.user,
            decisionReasion: request.evaluation.reason,
            properties: PropertiesBuilder().add(request.properties).add(evaluation.properties).build()
        )
    }
}
