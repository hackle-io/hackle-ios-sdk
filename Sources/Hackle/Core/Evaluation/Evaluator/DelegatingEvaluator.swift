import Foundation

class DelegatingEvaluator: Evaluator {

    private let evaluatorFactory: EvaluatorFactory

    init(evaluatorFactory: EvaluatorFactory) {
        self.evaluatorFactory = evaluatorFactory
    }

    func evaluate<R: EvaluateResponse>(request: EvaluateRequest, context: EvaluatorContext) throws -> R {
        try evaluatorFactory.get(request: request).evaluate(request: request, context: context)
    }

    func record(request: EvaluateRequest, response: EvaluateResponse) {
        try? evaluatorFactory.get(request: request).record(request: request, response: response)
    }
}
