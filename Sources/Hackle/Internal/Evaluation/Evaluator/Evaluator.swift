import Foundation

protocol Evaluator {
    func evaluate<Evaluation>(request: EvaluatorRequest, context: EvaluatorContext) throws -> Evaluation where Evaluation: EvaluatorEvaluation
}

enum EvaluatorType: String {
    case experiment = "EXPERIMENT"
    case remoteConfig = "REMOTE_CONFIG"
}

struct EvaluatorKey: Equatable {
    let type: EvaluatorType
    let id: Int64

    public static func ==(lhs: EvaluatorKey, rhs: EvaluatorKey) -> Bool {
        lhs.type == rhs.type && lhs.id == rhs.id
    }
}

protocol EvaluatorRequest {
    var key: EvaluatorKey { get }
    var workspace: Workspace { get }
    var user: HackleUser { get }
}

protocol EvaluatorEvaluation {
    var reason: String { get }
    var targetEvaluations: [EvaluatorEvaluation] { get }
}

protocol EvaluatorContext {
    var stack: [EvaluatorRequest] { get }
    var targetEvaluations: [EvaluatorEvaluation] { get }

    func contains(_ request: EvaluatorRequest) -> Bool
    func add(_ request: EvaluatorRequest)
    func remove(_ request: EvaluatorRequest)

    func get(_ experiment: Experiment) -> EvaluatorEvaluation?
    func add(_ evaluation: EvaluatorEvaluation)
}

class Evaluators {

    static func context() -> EvaluatorContext {
        DefaultContext()
    }

    private class DefaultContext: EvaluatorContext {
        private(set) var stack: [EvaluatorRequest] = []
        private(set) var targetEvaluations: [EvaluatorEvaluation] = []

        func contains(_ request: EvaluatorRequest) -> Bool {
            stack.contains { it in
                it.key == request.key
            }
        }

        func add(_ request: EvaluatorRequest) {
            stack.append(request)
        }

        func remove(_ request: EvaluatorRequest) {
            stack.removeAll { it in
                it.key == request.key
            }
        }

        func get(_ experiment: Experiment) -> EvaluatorEvaluation? {
            targetEvaluations.lazy
                .compactMap { it in
                    it as? ExperimentEvaluation
                }
                .first { it in
                    it.experiment.id == experiment.id
                }
        }

        func add(_ evaluation: EvaluatorEvaluation) {
            targetEvaluations.append(evaluation)
        }
    }
}
