import Foundation

class EvaluatorFactory {

    private var evaluators: [any ContextualEvaluator] = []

    func add(_ evaluator: any ContextualEvaluator) {
        evaluators.append(evaluator)
    }

    func get(request: EvaluateRequest) throws -> any ContextualEvaluator {
        guard let evaluator = evaluators.first(where: { $0.supports(request: request) }) else {
            throw HackleError.error("Unsupported EvaluateRequest [\(request)]")
        }
        return evaluator
    }
}
