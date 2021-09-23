import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockValueOperatorMatcher: Mock, ValueOperatorMatcher {
    lazy var matchesMock = MockFunction(self, matches)

    func matches(userValue: Any, match: Target.Match) -> Bool {
        call(matchesMock, args: (userValue, match))
    }
}