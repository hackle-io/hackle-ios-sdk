import Foundation
import Mockery
@testable import Hackle


class MockExperimentTargetRuleDeterminer: Mock, ExperimentTargetRuleDeterminer {

    lazy var determineTargetRuleOrNilMock = MockFunction(self, determineTargetRuleOrNil)

    func determineTargetRuleOrNil(workspace: Workspace, experiment: Experiment, user: HackleUser) -> TargetRule? {
        call(determineTargetRuleOrNilMock, args: (workspace, experiment, user))
    }
}