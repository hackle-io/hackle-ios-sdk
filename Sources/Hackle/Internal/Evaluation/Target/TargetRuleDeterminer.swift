import Foundation

protocol TargetRuleDeterminer {
    func determineTargetRuleOrNil(workspace: Workspace, experiment: RunningExperiment, user: HackleUser) -> TargetRule?
}

class DefaultTargetRuleDeterminer: TargetRuleDeterminer {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func determineTargetRuleOrNil(workspace: Workspace, experiment: RunningExperiment, user: HackleUser) -> TargetRule? {
        experiment.targetRules.first { it in
            targetMatcher.matches(target: it.target, workspace: workspace, user: user)
        }
    }
}
