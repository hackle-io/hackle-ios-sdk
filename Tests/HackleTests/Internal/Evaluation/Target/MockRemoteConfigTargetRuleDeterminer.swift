import Foundation
import Mockery
@testable import Hackle

class MockRemoteConfigTargetRuleDeterminer: Mock, RemoteConfigTargetRuleDeterminer {

    lazy var determineTargetRuleOrNilMock = MockFunction(self, determineTargetRuleOrNil)

    func determineTargetRuleOrNil(workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser) throws -> RemoteConfigParameter.TargetRule? {
        call(determineTargetRuleOrNilMock, args: (workspace, parameter, user))
    }
}