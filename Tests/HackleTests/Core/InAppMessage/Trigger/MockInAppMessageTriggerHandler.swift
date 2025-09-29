import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageTriggerHandler: Mock, InAppMessageTriggerHandler {
    lazy var handleMock = MockFunction(self, handle)

    func handle(trigger: InAppMessageTrigger) {
        call(handleMock, args: trigger)
    }
}
