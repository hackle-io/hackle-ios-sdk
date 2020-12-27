//
// Created by yong on 2020/12/11.
//

import Foundation
import Mockery
@testable import Hackle

class MockDecider: Mock, Decider {

    lazy var decideMock = MockFunction(self, decide)

    func decide(experiment: Experiment, user: User) -> Decision {
        call(decideMock, args: (experiment, user))
    }
}
