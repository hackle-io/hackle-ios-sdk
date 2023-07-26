import Foundation
import Mockery
@testable import Hackle


class MockInAppMessageActionHandler: Mock, InAppMessageActionHandler {

    var supportsReturn: Bool

    init(supportsReturn: Bool = true) {
        self.supportsReturn = supportsReturn
        super.init()
    }

    func supports(action: InAppMessage.Action) -> Bool {
        supportsReturn
    }

    lazy var handleMock = MockFunction(self, handle)

    func handle(view: InAppMessageView, action: InAppMessage.Action) {
        call(handleMock, args: (view, action))
    }
}