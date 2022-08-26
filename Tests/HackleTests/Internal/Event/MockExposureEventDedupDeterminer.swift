//
//  MockExposureEventDedupDeterminer.swift
//  HackleTests
//
//  Created by yong on 2022/08/25.
//

import Foundation
import Mockery
@testable import Hackle

class MockExposureEventDedupDeterminer: Mock, ExposureEventDedupDeterminer {

    lazy var isDedupTargetMock = MockFunction(self, isDedupTarget)

    func isDedupTarget(event: UserEvent) -> Bool {
        call(isDedupTargetMock, args: event)
    }
}
