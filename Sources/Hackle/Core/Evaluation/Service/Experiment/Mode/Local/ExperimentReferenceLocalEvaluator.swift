//
//  ExperimentReferenceLocalEvaluator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/2/25.
//

import Foundation

protocol ExperimentReferenceLocalEvaluator: ReferenceLocalEvaluator where Reference == ExperimentConfig, ReferenceEvaluation == ExperimentEvaluation {
    var evaluator: Evaluator { get }

    func resolveEvaluation(sourceRequest: LocalEvaluateRequest, experimentResponse: ExperimentEvaluateResponse) throws -> ExperimentEvaluation
}

extension ExperimentReferenceLocalEvaluator {

    func cachedEvaluation(context: EvaluatorContext, reference: ExperimentConfig) -> ExperimentEvaluation? {
        context.get(reference) as? ExperimentEvaluation
    }

    func doEvaluate(sourceRequest: LocalEvaluateRequest, context: EvaluatorContext, reference: ExperimentConfig) throws -> ExperimentEvaluation {
        let experimentRequest = ExperimentLocalEvaluateRequest.of(requestedBy: sourceRequest, experiment: reference)
        let experimentResponse: ExperimentEvaluateResponse = try evaluator.evaluate(request: experimentRequest, context: context)
        return try resolveEvaluation(sourceRequest: sourceRequest, experimentResponse: experimentResponse)
    }
}
