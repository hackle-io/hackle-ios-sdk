import Foundation

protocol ExperimentTargetDeterminer {
    func isUserInExperimentTarget(workspace: Workspace, experiment: RunningExperiment, user: HackleUser) -> Bool
}

class DefaultExperimentTargetDeterminer: ExperimentTargetDeterminer {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func isUserInExperimentTarget(workspace: Workspace, experiment: RunningExperiment, user: HackleUser) -> Bool {
        if experiment.targetAudiences.isEmpty {
            return true
        }

        return experiment.targetAudiences.contains { it in
            targetMatcher.matches(target: it, workspace: workspace, user: user)
        }
    }
}
