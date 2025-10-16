import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessagePresentProcessor: Mock, InAppMessagePresentProcessor {

    lazy var processMock = MockFunction.throwable(self, process)

    func process(request: InAppMessagePresentRequest) throws -> InAppMessagePresentResponse {
        return try call(processMock, args: request)
    }
}
