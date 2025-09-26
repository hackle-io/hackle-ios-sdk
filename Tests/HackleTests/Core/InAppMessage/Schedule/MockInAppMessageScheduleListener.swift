import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageScheduleListener: Mock, InAppMessageScheduleListener {

    lazy var onScheduleMock = MockFunction(self, onSchedule)

    func onSchedule(request: InAppMessageScheduleRequest) {
        return call(onScheduleMock, args: request)
    }
}
