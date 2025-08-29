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

    private let flowFactory: ExperimentFlowFactory

    init(flowFactory: ExperimentFlowFactory) {
        self.flowFactory = flowFactory
    }

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation {
        let flow = flowFactory.get(experimentType: request.experiment.type)
        guard let evaluation = try flow.evaluate(request: request, context: context) else {
            return try ExperimentEvaluation.ofDefault(request: request, context: context, reason: DecisionReason.TRAFFIC_NOT_ALLOCATED)
        }
        return evaluation
    }
}
