import Foundation

protocol TargetRuleDeterminer {
    func determineTargetRuleOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> TargetRule?
}

class DefaultTargetRuleDeterminer: TargetRuleDeterminer {

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
