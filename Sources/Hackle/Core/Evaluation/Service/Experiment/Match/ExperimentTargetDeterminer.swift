import Foundation

protocol ExperimentTargetDeterminer {
    func isUserInExperimentTarget(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool
}

class DefaultExperimentTargetDeterminer: ExperimentTargetDeterminer {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func isUserInExperimentTarget(request: ExperimentLocalEvaluateRequest, context: EvaluatorContext) throws -> Bool {
        if request.experimentConfig.targetAudiences.isEmpty {
            return true
        }

        return try request.experimentConfig.targetAudiences.contains { it in
            try targetMatcher.matches(request: request, context: context, target: it)
        }
    }
}
