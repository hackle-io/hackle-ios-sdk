//
// Created by yong on 2020/12/16.
//

import Foundation
import Mockery
@testable import Hackle

class MockSlotNumberCalculator: Mock, SlotNumberCalculator {

    lazy var mockCalculate = MockFunction(self, calculate)

    func calculate(seed: Int32, slotSize: Int32, userId: String) -> Int {
        call(mockCalculate, args: (seed, slotSize, userId))
    }
}
