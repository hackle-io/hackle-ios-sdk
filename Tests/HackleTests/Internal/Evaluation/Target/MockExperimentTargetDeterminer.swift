import Foundation
import Mockery
@testable import Hackle


class MockExperimentTargetDeterminer: Mock, ExperimentTargetDeterminer {

    lazy var isUserInExperimentTargetMock = MockFunction(self, isUserInExperimentTarget)

    func isUserInExperimentTarget(workspace: Workspace, experiment: RunningExperiment, user: User) -> Bool {
        call(isUserInExperimentTargetMock, args: (workspace, experiment, user))
    }
}