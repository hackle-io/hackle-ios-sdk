//
// Created by yong on 2020/12/21.
//

import Foundation
import Mockery
@testable import Hackle

class MockScheduler: Mock, Scheduler {

    lazy var scheduleMock = MockFunction(self, schedule)

    func schedule(delay: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
        call(scheduleMock, args: (delay, task))
    }

    lazy var schedulePeriodicallyMock = MockFunction(self, schedulePeriodically)

    func schedulePeriodically(delay: TimeInterval, period: TimeInterval, task: @escaping () -> ()) -> ScheduledJob {
        call(schedulePeriodicallyMock, args: (delay, period, task))
    }
}

class MockScheduledJob: Mock, ScheduledJob {
    var isCompleted: Bool = false

    lazy var cancelMock = MockFunction(self, cancel)

    func cancel() {
        call(cancelMock, args: ())
    }
}