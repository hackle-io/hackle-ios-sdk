//
// Created by yong on 2020/12/20.
//

import Foundation
import Mockery
@testable import Hackle

class MockUserEventDispatcher: Mock, UserEventDispatcher {

    lazy var dispatchMock = MockFunction(self, dispatch)

    func dispatch(events: [EventEntity]) {
        call(dispatchMock, args: events)
    }
}
