//
//  DelegatingEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation


class DelegatingEvaluator: Evaluator {

    private var evaluators: [any ContextualEvaluator] = []

    func add(_ evaluator: any ContextualEvaluator) {
        evaluators.append(evaluator)
    }

    func evaluate<Evaluation>(request: EvaluatorRequest, context: EvaluatorContext) throws -> Evaluation where Evaluation: EvaluatorEvaluation {
        guard let evaluator = evaluators.first(where: { it in it.support(request: request) }) else {
            throw HackleError.error("Unsupported EvaluatorRequest [\(request)]")
        }
        return try evaluator.evaluate(request: request, context: context)
    }
}
