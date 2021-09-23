import Foundation
import Mockery
@testable import Hackle


class MockTargetRuleDeterminer: Mock, TargetRuleDeterminer {

    lazy var determineTargetRuleOrNilMock = MockFunction(self, determineTargetRuleOrNil)

    func determineTargetRuleOrNil(workspace: Workspace, experiment: RunningExperiment, user: User) -> TargetRule? {
        call(determineTargetRuleOrNilMock, args: (workspace, experiment, user))
    }
}