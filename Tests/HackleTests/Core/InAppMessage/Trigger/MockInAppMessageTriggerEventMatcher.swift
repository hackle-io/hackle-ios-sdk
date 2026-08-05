import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageTriggerEventMatcher: Mock, InAppMessageTriggerEventMatcher {

    lazy var matchesMock = MockFunction.throwable(self, matches)

    func matches(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> Bool {
        return try call(matchesMock, args: (workspace, inAppMessage, event))
    }
}
