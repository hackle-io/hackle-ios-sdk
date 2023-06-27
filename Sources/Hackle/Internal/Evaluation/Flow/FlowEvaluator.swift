//
//  FlowEvaluator.swift
//  Hackle
//
//  Created by yong on 2023/06/26.
//

import Foundation


protocol FlowEvaluator {
    func evaluate<Request: EvaluatorRequest, Evaluation: EvaluatorEvaluation>(
        request: Request,
        context: EvaluatorContext,
        nextFlow: EvaluationFlow<Request, Evaluation>
    ) throws -> Evaluation?
}