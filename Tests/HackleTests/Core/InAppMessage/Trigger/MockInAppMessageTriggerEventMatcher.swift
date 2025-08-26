import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageTriggerEventMatcher: Mock, InAppMessageTriggerEventMatcher {

    lazy var matchesMock = MockFunction.throwable(self, matches)

    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> Bool {
        return try call(matchesMock, args: (workspace, inAppMessage, event))
    }
}


class InAppMessageTriggerEventMatcherStub: InAppMessageTriggerEventMatcher {

    var matches: [Bool] {
        didSet {
            count = 0
        }
    }
    var count = 0

    init(matches: [Bool] = []) {
        self.matches = matches
    }

    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> Bool {
        let isMatch = matches[count]
        count += 1
        return isMatch
    }
}