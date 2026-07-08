import Foundation

final class InAppMessageEligibilityLocalEvaluator: InAppMessageEligibilityEvaluator {

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

    func record(request: EvaluateRequest, response: EvaluateResponse) {
        eventRecorder.record(response: response)
        guard let eligibilityResponse = response as? InAppMessageEligibilityEvaluateResponse else {
            return
        }
        if !eligibilityResponse.eligibilityEvaluation.eligibilityResult.isEligible, let layout = eligibilityResponse.layout {
            eventRecorder.record(response: layout)
        }
    }
}
