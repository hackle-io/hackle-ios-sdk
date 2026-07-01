//
//  ContextualEvaluator.swift
//  Hackle
//

import Foundation

protocol ContextualEvaluator: Evaluator {

    associatedtype Request: EvaluateRequest
    associatedtype Response: EvaluateResponse

    var eventRecorder: EvaluationEventRecorder { get }

    func doEvaluate(request: Request, context: EvaluatorContext) throws -> Response
}

extension ContextualEvaluator {

    func supports(request: EvaluateRequest) -> Bool {
        request is Request
    }

    func evaluate<R: EvaluateResponse>(request: EvaluateRequest, context: EvaluatorContext) throws -> R {
        if context.contains(request) {
            throw HackleError.error("Circular evaluation has occurred \(context.stack) - \(request)")
        }
        context.add(request)
        defer { context.remove(request) }
        let response = try doEvaluate(request: request as! Self.Request, context: context)
        return response as! R
    }

    func record(request: EvaluateRequest, response: EvaluateResponse) {
        eventRecorder.record(response: response)
    }
}
