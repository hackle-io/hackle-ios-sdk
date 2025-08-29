import Foundation

class InAppMessageEligibilityEvaluator: InAppMessageEvaluator {

    typealias Request = InAppMessageEligibilityRequest
    typealias Evaluation = InAppMessageEligibilityEvaluation

    private let flow: InAppMessageEligibilityFlow
    private let eventRecorder: EvaluationEventRecorder

    init(flow: InAppMessageEligibilityFlow, eventRecorder: EvaluationEventRecorder) {
        self.flow = flow
        self.eventRecorder = eventRecorder
    }

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {
        guard let evaluation = try flow.evaluate(request: request, context: context) else {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
        }
        return evaluation
    }

    func recordInternal(request: Request, evaluation: Evaluation) {
        eventRecorder.record(request: request, evaluation: evaluation)
        if !evaluation.isEligible, let layoutEvaluation = evaluation.layoutEvaluation {
            eventRecorder.record(request: layoutEvaluation.request, evaluation: layoutEvaluation)
        }
    }
}
