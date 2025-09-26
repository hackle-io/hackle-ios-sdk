import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessagePresenter: Mock, InAppMessagePresenter {

    lazy var presentMock = MockFunction(self, present)

    func present(context: InAppMessagePresentationContext) {
        call(presentMock, args: context)
    }
}
