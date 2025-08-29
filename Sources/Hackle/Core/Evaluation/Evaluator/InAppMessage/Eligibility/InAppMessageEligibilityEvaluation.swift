import Foundation

class InAppMessageEligibilityEvaluation: InAppMessageEvaluatorEvaluation {
    let reason: String
    let targetEvaluations: [EvaluatorEvaluation]
    let inAppMessage: InAppMessage
    let isEligible: Bool
    let layoutEvaluation: InAppMessageLayoutEvaluation?

    init(
        reason: String,
        targetEvaluations: [EvaluatorEvaluation],
        inAppMessage: InAppMessage,
        isEligible: Bool,
        layoutEvaluation: InAppMessageLayoutEvaluation?
    ) {
        self.reason = reason
        self.targetEvaluations = targetEvaluations
        self.inAppMessage = inAppMessage
        self.isEligible = isEligible
        self.layoutEvaluation = layoutEvaluation
    }

    static func of(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        reason: String,
        isEligible: Bool
    ) -> InAppMessageEligibilityEvaluation {
        return InAppMessageEligibilityEvaluation(
            reason: reason,
            targetEvaluations: context.targetEvaluations,
            inAppMessage: request.inAppMessage,
            isEligible: isEligible,
            layoutEvaluation: context.get(InAppMessageLayoutEvaluation.self)
        )
    }

    static func eligible(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        reason: String
    ) -> InAppMessageEligibilityEvaluation {
        return .of(
            request: request,
            context: context,
            reason: reason,
            isEligible: true
        )
    }

    static func ineligible(
        request: InAppMessageEligibilityRequest,
        context: EvaluatorContext,
        reason: String
    ) -> InAppMessageEligibilityEvaluation {
        return .of(
            request: request,
            context: context,
            reason: reason,
            isEligible: false
        )
    }
}
