import Foundation
import Mockery
@testable import Hackle

class MockRemoteConfigTargetRuleMatcher: Mock, RemoteConfigTargetRuleMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(targetRule: RemoteConfigParameter.TargetRule, workspace: Workspace, parameter: RemoteConfigParameter, user: HackleUser) throws -> Bool {
        call(matchesMock, args: (targetRule, workspace, parameter, user))
    }
}