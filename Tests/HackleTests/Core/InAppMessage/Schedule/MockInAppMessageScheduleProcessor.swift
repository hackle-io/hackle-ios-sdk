import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageScheduleProcessor: Mock, InAppMessageScheduleProcessor {
    lazy var processMock = MockFunction(self, process)

    func process(request: InAppMessageScheduleRequest) -> InAppMessageScheduleResponse {
        return call(processMock, args: request)
    }
}
