import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageRecorder: Mock, InAppMessageRecorder {
    lazy var recordMock = MockFunction(self, record)

    func record(request: InAppMessagePresentRequest, response: InAppMessagePresentResponse) {
        call(recordMock, args: (request, response))
    }
}
