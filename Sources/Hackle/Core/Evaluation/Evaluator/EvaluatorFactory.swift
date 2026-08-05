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

extension EvaluatorFactory {
    func experiment(_ request: ExperimentEvaluateRequest) throws -> any ExperimentEvaluator {
        guard let evaluator = try get(request: request) as? any ExperimentEvaluator else {
            throw HackleError.error("Unsupported experiment evaluator")
        }
        return evaluator
    }

    func remoteConfig(_ request: RemoteConfigEvaluateRequest) throws -> any RemoteConfigEvaluator {
        guard let evaluator = try get(request: request) as? any RemoteConfigEvaluator else {
            throw HackleError.error("Unsupported remoteConfig evaluator")
        }
        return evaluator
    }

    func inAppMessage(_ request: InAppMessageEligibilityEvaluateRequest) throws -> any InAppMessageEligibilityEvaluator {
        guard let e = try get(request: request) as? any InAppMessageEligibilityEvaluator else {
            throw HackleError.error("Unsupported IAM eligibility evaluator")
        }
        return e
    }

    func inAppMessage(_ request: InAppMessageLayoutEvaluateRequest) throws -> any InAppMessageLayoutEvaluator {
        guard let e = try get(request: request) as? any InAppMessageLayoutEvaluator else {
            throw HackleError.error("Unsupported IAM layout evaluator")
        }
        return e
    }
}
