import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockTargetMatcher: Mock, TargetMatcher {

    lazy var matchesMock = MockFunction(self, matches)

    func matches(target: Target, workspace: Workspace, user: HackleUser) throws -> Bool {
        call(matchesMock, args: (target, workspace, user))
    }
}