import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageDeliverProcessor: Mock, InAppMessageDeliverProcessor {
    lazy var processMock = MockFunction.throwable(self, process)

    func process(request: InAppMessageDeliverRequest) throws -> InAppMessageDeliverResponse {
        return try call(processMock, args: request)
    }
}
