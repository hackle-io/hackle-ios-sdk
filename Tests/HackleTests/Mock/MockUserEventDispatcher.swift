//
// Created by yong on 2020/12/20.
//

import Foundation
import MockingKit
@testable import Hackle

class MockUserEventDispatcher: Mock, UserEventDispatcher {
    var nextFlushAllowDate: TimeInterval? = nil
    
    lazy var dispatchMock = MockFunction(self, dispatch)

    func dispatch(events: [EventEntity]) {
        call(dispatchMock, args: events)
    }
}
