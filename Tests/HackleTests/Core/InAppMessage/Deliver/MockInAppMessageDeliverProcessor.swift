import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageDeliverProcessor: Mock, InAppMessageDeliverProcessor {
    lazy var processMock = MockFunction(self, process)

    func process(request: InAppMessageDeliverRequest) -> InAppMessageDeliverResponse {
        return call(processMock, args: request)
    }
}
