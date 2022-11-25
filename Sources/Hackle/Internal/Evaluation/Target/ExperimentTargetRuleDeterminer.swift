import Foundation

protocol ExperimentTargetRuleDeterminer {
    func determineTargetRuleOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> TargetRule?
}

class DefaultExperimentTargetRuleDeterminer: ExperimentTargetRuleDeterminer {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func determineTargetRuleOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> TargetRule? {
        try experiment.targetRules.first { it in
            try targetMatcher.matches(target: it.target, workspace: workspace, user: user)
        }
    }
}
