import Foundation

final class InAppMessageEligibilityLocalEvaluator: LocalEvaluator, InAppMessageEligibilityEvaluator {

    typealias Request = InAppMessageEligibilityLocalEvaluateRequest
    typealias Response = InAppMessageEligibilityEvaluateResponse

    private let evaluationFlowFactory: InAppMessageEligibilityLocalEvaluationFlowFactory
    let eventRecorder: EvaluationEventRecorder

    init(evaluationFlowFactory: InAppMessageEligibilityLocalEvaluationFlowFactory, eventRecorder: EvaluationEventRecorder) {
        self.evaluationFlowFactory = evaluationFlowFactory
        self.eventRecorder = eventRecorder
    }

    func doEvaluate(request: InAppMessageEligibilityLocalEvaluateRequest, context: EvaluatorContext) throws -> InAppMessageEligibilityEvaluateResponse {
        let evaluationFlow = evaluationFlowFactory.get(request: request)
        let result = try evaluationFlow.evaluate(request: request, context: context)?.eligibilityResult
            ?? InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
        return InAppMessageEligibilityEvaluateResponse.of(request: request, context: context, result: result)
    }
}
