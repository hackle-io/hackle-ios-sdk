import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockConditionMatcher: ConditionMatcher {

    private let isMatches: Bool
    var callCount = 0

    init(_ isMatches: Bool) {
        self.isMatches = isMatches
    }

    func matches(condition: Target.Condition, workspace: Workspace, user: HackleUser) -> Bool {
        callCount = callCount + 1
        return isMatches
    }
}