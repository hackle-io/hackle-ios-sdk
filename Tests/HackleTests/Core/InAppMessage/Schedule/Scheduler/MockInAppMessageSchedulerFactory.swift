import Foundation
import Mockery
@testable import Hackle

class MockInAppMessageSchedulerFactory: Mock, InAppMessageSchedulerFactory {

    lazy var getMock = MockFunction(self, get)

    func get(scheduleType: InAppMessageScheduleType) throws -> InAppMessageScheduler {
        return call(getMock, args: scheduleType)
    }
}
