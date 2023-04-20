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
        let evaluationFlow = evaluationFlowFactory.getFlow(experimentType: request.experiment.type)
        return try evaluationFlow.evaluate(request: request, context: context)
    }
}
