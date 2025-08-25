import Foundation

class InAppMessageLayoutEvaluation: EvaluatorEvaluation {

    let reason: String
    let targetEvaluations: [EvaluatorEvaluation]
    let inAppMessage: InAppMessage
    let message: InAppMessage.Message
    let properties: [String: Any]

    init(
        reason: String,
        targetEvaluations: [EvaluatorEvaluation],
        inAppMessage: InAppMessage,
        message: InAppMessage.Message,
        properties: [String: Any]
    ) {
        self.reason = reason
        self.targetEvaluations = targetEvaluations
        self.inAppMessage = inAppMessage
        self.message = message
        self.properties = properties
    }

    static func of(
        request: InAppMessageLayoutRequest,
        context: EvaluatorContext,
        message: InAppMessage.Message
    ) -> InAppMessageLayoutEvaluation {
        return InAppMessageLayoutEvaluation(
            reason: DecisionReason.IN_APP_MESSAGE_TARGET,
            targetEvaluations: context.targetEvaluations,
            inAppMessage: request.inAppMessage,
            message: message,
            properties: context.properties
        )
    }
}
