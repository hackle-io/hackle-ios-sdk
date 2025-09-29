import Foundation
import MockingKit
@testable import Hackle

class MockUserEventDedupDeterminer: Mock, UserEventDedupDeterminer {
    lazy var isDedupTargetMock = MockFunction(self, isDedupTarget)

    func isDedupTarget(event: UserEvent) -> Bool {
        call(isDedupTargetMock, args: event)
    }
}