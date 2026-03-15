import Foundation
@testable import Hackle
import MockingKit

class MockInAppMessageActionHandler: Mock, InAppMessageActionHandler {
    lazy var supportsMock = MockFunction(self, supports)
    func supports(action: InAppMessage.Action) -> Bool {
        return call(supportsMock, args: action)
    }

    lazy var handleMock = MockFunction(self, handle)
    func handle(view: InAppMessageView, action: InAppMessage.Action) {
        return call(handleMock, args: (view, action))
    }
}
