import Foundation
@testable import Hackle
import MockingKit

class MockInAppMessageViewEventHandler: Mock, InAppMessageViewEventHandler {
    var handleType: InAppMessageViewEventHandleType
    
    init(handleType: InAppMessageViewEventHandleType) {
        self.handleType = handleType
    }
    
    func supports(handleType: InAppMessageViewEventHandleType) -> Bool {
        return self.handleType == handleType
    }
    
    lazy var handleMock = MockFunction(self, handle)
    func handle(view: InAppMessageView, event: InAppMessageViewEvent) {
        return call(handleMock, args: (view, event))
    }
}
