import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageTriggerDeterminer: Mock, InAppMessageTriggerDeterminer {
    var eventMatcher: InAppMessageTriggerEventMatcher = MockInAppMessageTriggerEventMatcher()
    
    func workspace(user: HackleUser) -> (Workspace)? {
        return nil
    }
    
    func evaluate(workspace: Workspace, inAppMessage: InAppMessage, event: UserEvents.Track) throws -> InAppMessageEligibilityEvaluation {
        throw NSError()
    }
    
    lazy var determineMock = MockFunction.throwable(self, determine)
    func determine(event: UserEvent) throws -> InAppMessageTrigger? {
        return try call(determineMock, args: event)
    }
}
