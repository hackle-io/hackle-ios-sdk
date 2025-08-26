import Foundation
import Mockery
@testable import Hackle

class MockInAppMessagePresentProcessor: Mock, InAppMessagePresentProcessor {

    lazy var processMock = MockFunction(self, process)

    func process(request: InAppMessagePresentRequest) throws -> InAppMessagePresentResponse {
        return call(processMock, args: request)
    }
}
