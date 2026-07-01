import Foundation

protocol InAppMessageEvaluateProcessor {
    func process(type: InAppMessageEvaluateScope, request: InAppMessageEligibilityLocalEvaluateRequest) throws -> InAppMessageEligibilityEvaluation
}

class DefaultInAppMessageEvaluateProcessor: InAppMessageEvaluateProcessor {

    private let evaluateProcessor: EvaluateProcessor

    init(evaluateProcessor: EvaluateProcessor) {
        self.evaluateProcessor = evaluateProcessor
    }

    func process(
        type: InAppMessageEvaluateScope,
        request: InAppMessageEligibilityLocalEvaluateRequest
    ) throws -> InAppMessageEligibilityEvaluation {
        let eligibilityRequest = InAppMessageEligibilityLocalEvaluateRequest.of(
            workspace: request.workspace,
            inAppMessage: request.inAppMessage,
            user: request.user,
            scope: type,
            timestamp: request.timestamp
        )
        let response = try evaluateProcessor.inAppMessage(eligibilityRequest)
        return response.eligibilityEvaluation
    }
}
