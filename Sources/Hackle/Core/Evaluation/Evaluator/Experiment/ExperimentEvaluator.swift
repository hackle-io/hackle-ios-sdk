//
//  ExperimentEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation

class ExperimentEvaluator: ContextualEvaluator {

    typealias Request = ExperimentRequest
    typealias Evaluation = ExperimentEvaluation

    private let evaluationFlowFactory: EvaluationFlowFactory

    init(evaluationFlowFactory: EvaluationFlowFactory) {
        self.evaluationFlowFactory = evaluationFlowFactory
    }

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {
        let evaluationFlow = evaluationFlowFactory.getExperimentFlow(experimentType: request.experiment.type)
        guard let evaluation = try evaluationFlow.evaluate(request: request, context: context) else {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        }
        return evaluation
    }
}
