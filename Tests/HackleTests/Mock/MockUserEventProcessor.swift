//
// Created by yong on 2020/12/11.
//

import Foundation
import Mockery
@testable import Hackle

class MockUserEventProcessor: Mock, UserEventProcessor {

    lazy var processMock = MockFunction(self, process)

    func process(event: UserEvent) {
        call(processMock, args: (event))
    }

    lazy var startMock = MockFunction(self, start)

    func start() {
        call(startMock, args: ())
    }

    lazy var stopMock = MockFunction(self, stop)

    func stop() {
        call(stopMock, args: ())
    }

    lazy var initializeMock = MockFunction(self, initialize)

    func initialize() {
        call(initializeMock, args: ())
    }
    
    lazy var flushMock = MockFunction(self, flush)
    
    func flush() {
        call(flushMock, args: ())
    }
}
