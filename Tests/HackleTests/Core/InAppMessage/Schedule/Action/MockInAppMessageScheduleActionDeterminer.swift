import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageScheduleActionDeterminer: Mock, InAppMessageScheduleActionDeterminer {

    lazy var determineMock = MockFunction.throwable(self, determine)

    func determine(request: InAppMessageScheduleRequest) throws -> InAppMessageScheduleAction {
        return try call(determineMock, args: request)
    }
}
