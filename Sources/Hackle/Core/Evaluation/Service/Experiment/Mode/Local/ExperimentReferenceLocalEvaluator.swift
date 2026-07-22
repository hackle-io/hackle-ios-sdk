//
//  ExperimentReferenceLocalEvaluator.swift
//  Hackle
//

import Foundation

final class ExperimentReferenceLocalEvaluator: ReferenceLocalEvaluator {

    typealias Reference = ExperimentConfig
    typealias ReferenceEvaluation = ExperimentEvaluation

    private let evaluatorFactory: EvaluatorFactory

    init(evaluatorFactory: EvaluatorFactory) {
        self.evaluatorFactory = evaluatorFactory
    }

    func cachedEvaluation(context: EvaluatorContext, reference: ExperimentConfig) -> ExperimentEvaluation? {
        context.get(reference) as? ExperimentEvaluation
    }

    func doEvaluate(parentRequest: LocalEvaluateRequest, context: EvaluatorContext, reference: ExperimentConfig) throws -> ExperimentEvaluation {
        let experimentRequest = ExperimentLocalEvaluateRequest.of(requestedBy: parentRequest, experiment: reference)
        let experimentEvaluator = try evaluatorFactory.experiment(experimentRequest)
        let experimentResponse: ExperimentEvaluateResponse = try experimentEvaluator.evaluate(request: experimentRequest, context: context)
        return experimentResponse.experimentEvaluation
    }
}
