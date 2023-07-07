import Foundation

protocol ExperimentTargetRuleDeterminer {
    func determineTargetRuleOrNil(request: ExperimentRequest, context: EvaluatorContext) throws -> TargetRule?
}

class DefaultExperimentTargetRuleDeterminer: ExperimentTargetRuleDeterminer {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func determineTargetRuleOrNil(request: ExperimentRequest, context: EvaluatorContext) throws -> TargetRule? {
        try request.experiment.targetRules.first { it in
            try targetMatcher.matches(request: request, context: context, target: it.target)
        }
    }
}
