//
//  FlowEvaluator.swift
//  Hackle
//

import Foundation


protocol FlowEvaluator {
    func evaluate<Request: EvaluateRequest, E: Evaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, E>
    ) throws -> E?
}
