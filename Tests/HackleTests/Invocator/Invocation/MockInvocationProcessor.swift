import Foundation
@testable import Hackle
import MockingKit

class MockInvocationProcessor: Mock, InvocationProcessor {
    lazy var processMock = MockFunction(self, process)
    func process(request: InvocationRequest) -> InvocationResponse<Any> {
        return call(processMock, args: request)
    }
}
