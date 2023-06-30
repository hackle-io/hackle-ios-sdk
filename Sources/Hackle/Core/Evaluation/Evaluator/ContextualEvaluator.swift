//
//  ContextualEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/04/17.
//

import Foundation


protocol ContextualEvaluator: Evaluator {

    associatedtype Request: EvaluatorRequest
    associatedtype Evaluation: EvaluatorEvaluation

    func evaluateInternal(request: Request, context: EvaluatorContext) throws -> Evaluation
}


extension ContextualEvaluator {

    func support(request: EvaluatorRequest) -> Bool {
        request is Request
    }

    func evaluate<Evaluation>(
        request: EvaluatorRequest,
        context: EvaluatorContext
    ) throws -> Evaluation where Evaluation: EvaluatorEvaluation {
        if context.contains(request) {
            throw HackleError.error("Circular evaluation has occurred \(context.stack) - \(request)")
        }
        context.add(request)

        let evaluation = try evaluateInternal(request: request as! Self.Request, context: context)
        context.remove(request)
        return evaluation as! Evaluation
    }
}
