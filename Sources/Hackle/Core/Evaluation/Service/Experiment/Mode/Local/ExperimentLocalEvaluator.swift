//
//  ExperimentLocalEvaluator.swift
//  Hackle
//

import Foundation

final class ExperimentLocalEvaluator: ExperimentEvaluator {

    private let evaluationFlowFactory: ExperimentLocalEvaluationFlowFactory
    let eventRecorder: EvaluationEventRecorder

    init(evaluationFlowFactory: ExperimentLocalEvaluationFlowFactory, eventRecorder: EvaluationEventRecorder) {
        self.evaluationFlowFactory = evaluationFlowFactory
        self.eventRecorder = eventRecorder
    }

    func doEvaluate(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> ExperimentEvaluateResponse {
        let flow = evaluationFlowFactory.flow(experimentType: request.experiment.type)
        let evaluation: ExperimentEvaluation
        if let flowEvaluation = try flow.evaluate(request: request, context: context) {
            evaluation = flowEvaluation
        } else {
            let result = try ExperimentEvaluateResult.ofDefault(reason: DecisionReason.TRAFFIC_NOT_ALLOCATED, request: request)
            evaluation = ExperimentEvaluation(entity: request.experiment, result: result)
        }
        return ExperimentEvaluateResponse(
            user: request.user,
            workspace: request.workspace,
            evaluation: evaluation,
            references: context.references
        )
    }
}
