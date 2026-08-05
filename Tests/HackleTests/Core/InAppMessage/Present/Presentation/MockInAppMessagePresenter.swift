import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessagePresenter: Mock, InAppMessagePresenter {
    // MockFunction은 sync 함수 타입만 받으므로, async 프로토콜 메서드는 sync stub으로 참조를 만든다.
    lazy var presentMock = MockFunction(self, presentStub)

    private func presentStub(context: InAppMessagePresentationContext) -> InAppMessagePresentResponse {
        fatalError("presentStub is not invoked directly; it only exists to type the MockFunction reference")
    }

    func present(context: InAppMessagePresentationContext) async -> InAppMessagePresentResponse {
        call(presentMock, args: context)
    }
}
