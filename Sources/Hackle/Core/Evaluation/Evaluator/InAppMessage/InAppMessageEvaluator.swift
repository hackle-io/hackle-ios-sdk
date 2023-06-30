//
//  InAppMessageEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/06/01.
//

import Foundation

class InAppMessageEvaluator: ContextualEvaluator {

    typealias Request = InAppMessageRequest
    typealias Evaluation = InAppMessageEvaluation

    private let evaluationFlowFactory: EvaluationFlowFactory

    init(evaluationFlowFactory: EvaluationFlowFactory) {
        self.evaluationFlowFactory = evaluationFlowFactory
    }

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {
        let evaluationFlow = evaluationFlowFactory.getInAppMessageFlow()
        guard let evaluation = try evaluationFlow.evaluate(request: request, context: context) else {
            return InAppMessageEvaluation.of(request: request, context: context, reason: DecisionReason.NOT_IN_IN_APP_MESSAGE_TARGET)
        }
        return evaluation
    }
}
