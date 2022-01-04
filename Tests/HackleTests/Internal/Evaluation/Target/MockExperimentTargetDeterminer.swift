import Foundation
import Mockery
@testable import Hackle


class MockExperimentTargetDeterminer: Mock, ExperimentTargetDeterminer {

    lazy var isUserInExperimentTargetMock = MockFunction(self, isUserInExperimentTarget)

    func isUserInExperimentTarget(workspace: Workspace, experiment: Experiment, user: HackleUser) -> Bool {
        call(isUserInExperimentTargetMock, args: (workspace, experiment, user))
    }
}