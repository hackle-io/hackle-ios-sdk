import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageTriggerProcessor: Mock, InAppMessageTriggerProcessor {
    lazy var processMock = MockFunction(self, process)

    func process(event: UserEvent) {
        call(processMock, args: event)
    }
}
