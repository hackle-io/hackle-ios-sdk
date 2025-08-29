import Foundation

class InAppMessageLayoutEvaluation: InAppMessageEvaluatorEvaluation {

    let request: InAppMessageLayoutRequest
    let reason: String
    let targetEvaluations: [EvaluatorEvaluation]
    let message: InAppMessage.Message
    let properties: [String: Any]

    init(
        request: InAppMessageLayoutRequest,
        reason: String,
        targetEvaluations: [EvaluatorEvaluation],
        message: InAppMessage.Message,
        properties: [String: Any]
    ) {
        self.request = request
        self.reason = reason
        self.targetEvaluations = targetEvaluations
        self.message = message
        self.properties = properties
    }

    var inAppMessage: InAppMessage {
        return request.inAppMessage
    }
}

extension InAppMessageLayoutEvaluation {
    static func of(
        request: InAppMessageLayoutRequest,
        context: EvaluatorContext,
        message: InAppMessage.Message
    ) -> InAppMessageLayoutEvaluation {
        return InAppMessageLayoutEvaluation(
            request: request,
            reason: DecisionReason.IN_APP_MESSAGE_TARGET,
            targetEvaluations: context.targetEvaluations,
            message: message,
            properties: context.properties
        )
    }
}
