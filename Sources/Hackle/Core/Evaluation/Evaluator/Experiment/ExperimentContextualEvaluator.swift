//
//  ExperimentContextualEvaluator.swift
//  Hackle
//
//  Created by sungwoo.yeo on 5/2/25.
//

protocol ExperimentContextualEvaluator {
    var evaluator: Evaluator { get }

    func resolve(request: EvaluatorRequest, context: EvaluatorContext, evaluation: ExperimentEvaluation) throws -> ExperimentEvaluation
}

extension ExperimentContextualEvaluator {
    func evaluate(request: EvaluatorRequest, context: EvaluatorContext, experiment: Experiment) throws -> ExperimentEvaluation {
        guard let evaluation = context.get(experiment) else {
            return try evaluateInternal(request: request, context: context, experiment: experiment)
        }

        guard let experimentEvaluation = evaluation as? ExperimentEvaluation else {
            throw HackleError.error("Unsupported evaluation: \(type(of: evaluation)) (expected: \(ExperimentEvaluation.self))")
        }
        return experimentEvaluation
    }

    fileprivate func evaluateInternal(request: EvaluatorRequest, context: EvaluatorContext, experiment: Experiment) throws -> ExperimentEvaluation {
        let experimentRequest = ExperimentRequest.of(requestedBy: request, experiment: experiment)
        let evaluation: ExperimentEvaluation = try evaluator.evaluate(request: experimentRequest, context: context)
        let resolvedEvaluation = try resolve(request: request, context: context, evaluation: evaluation)
        context.add(resolvedEvaluation)
        return resolvedEvaluation
    }
}
