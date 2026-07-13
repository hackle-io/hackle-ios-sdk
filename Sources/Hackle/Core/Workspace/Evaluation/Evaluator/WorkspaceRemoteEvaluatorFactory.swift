import Foundation

class WorkspaceRemoteEvaluatorFactory {

    private let evaluators: [WorkspaceRemoteEvaluator]

    init(evaluators: [WorkspaceRemoteEvaluator]) {
        self.evaluators = evaluators
    }

    func get(scope: WorkspaceEvaluateScope) throws -> WorkspaceRemoteEvaluator {
        guard let evaluator = evaluators.first(where: { it in it.supports(scope: scope) }) else {
            throw HackleError.error("Not found WorkspaceRemoteEvaluator (scope=\(scope.rawValue))")
        }
        return evaluator
    }
}
