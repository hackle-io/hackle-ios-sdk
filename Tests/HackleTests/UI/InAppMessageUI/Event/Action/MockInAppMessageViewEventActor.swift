import Foundation
@testable import Hackle
import MockingKit

class MockInAppMessageViewEventActor: Mock, InAppMessageViewEventActor {
    lazy var supportsMock = MockFunction(self, supports)
    func supports(type: InAppMessageViewEventType) -> Bool {
        return call(supportsMock, args: type)
    }

    lazy var actionMock = MockFunction(self, action)
    func action(view: InAppMessageView, event: InAppMessageViewEvent) {
        return call(actionMock, args: (view, event))
    }
}
