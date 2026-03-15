import Foundation
@testable import Hackle
import MockingKit

class MockInAppMessageViewEventProcessor: Mock, InAppMessageViewEventProcessor {
    lazy var processMock = MockFunction(self, process)
    func process(view: InAppMessageView, event: InAppMessageViewEvent, types: [InAppMessageViewEventHandleType]) {
        return call(processMock, args: (view, event, types))
    }
}
