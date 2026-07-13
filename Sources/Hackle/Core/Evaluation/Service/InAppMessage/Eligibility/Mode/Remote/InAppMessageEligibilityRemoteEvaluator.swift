import Foundation

final class InAppMessageEligibilityRemoteEvaluator: RemoteEvaluator, InAppMessageEligibilityEvaluator {

    typealias Request = InAppMessageEligibilityRemoteEvaluateRequest
    typealias Response = InAppMessageEligibilityEvaluateResponse

    private let evaluationFlowFactory: InAppMessageEligibilityRemoteEvaluationFlowFactory
    let eventRecorder: EvaluationEventRecorder

    init(
        evaluationFlowFactory: InAppMessageEligibilityRemoteEvaluationFlowFactory,
        eventRecorder: EvaluationEventRecorder
    ) {
        self.evaluationFlowFactory = evaluationFlowFactory
        self.eventRecorder = eventRecorder
    }

    func remoteEvaluate(request: InAppMessageEligibilityRemoteEvaluateRequest, context: EvaluatorContext) throws -> InAppMessageEligibilityEvaluateResponse {
        let evaluationFlow = evaluationFlowFactory.get(request: request)
        let result = try evaluationFlow.evaluate(request: request, context: context)?.eligibilityResult
            ?? InAppMessageEligibilityEvaluateResult.ineligible(reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
        return InAppMessageEligibilityEvaluateResponse.of(request: request, context: context, result: result)
    }
}
