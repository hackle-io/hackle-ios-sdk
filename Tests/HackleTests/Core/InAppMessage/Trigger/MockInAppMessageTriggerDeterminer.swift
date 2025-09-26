import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageTriggerDeterminer: Mock, InAppMessageTriggerDeterminer {
    lazy var determineMock = MockFunction.throwable(self, determine)

    func determine(event: UserEvent) throws -> InAppMessageTrigger? {
        return try call(determineMock, args: event)
    }
}
