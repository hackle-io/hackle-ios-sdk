import Foundation

class InAppMessageEligibilityEvaluator: ContextualEvaluator {

    typealias Request = InAppMessageEligibilityRequest
    typealias Evaluation = InAppMessageEligibilityEvaluation

    private let evaluationFlowFactory: EvaluationFlowFactory

    init(evaluationFlowFactory: EvaluationFlowFactory) {
        self.evaluationFlowFactory = evaluationFlowFactory
    }

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {
        let evaluationFlow = evaluationFlowFactory.getInAppMessageFlow()
        guard let evaluation = try evaluationFlow.evaluate(request: request, context: context) else {
            return InAppMessageEligibilityEvaluation.ineligible(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
        }
        return evaluation
    }
}
