import Foundation

protocol ExperimentTargetDeterminer {
    func isUserInExperimentTarget(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Bool
}

class DefaultExperimentTargetDeterminer: ExperimentTargetDeterminer {

    private let targetMatcher: TargetMatcher

    init(targetMatcher: TargetMatcher) {
        self.targetMatcher = targetMatcher
    }

    func isUserInExperimentTarget(workspace: Workspace, experiment: Experiment, user: HackleUser) throws -> Bool {
        if experiment.targetAudiences.isEmpty {
            return true
        }

        return try experiment.targetAudiences.contains { it in
            try targetMatcher.matches(target: it, workspace: workspace, user: user)
        }
    }
}
