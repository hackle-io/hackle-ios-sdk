//
//  MockSynchronizer.swift
//  HackleTests
//
//  Created by yong on 2023/10/02.
//

import Foundation
import Mockery
@testable import Hackle

class MockSynchronizer: Mock, Synchronizer {

    lazy var syncMock = MockFunction(self, sync)

    func sync(completion: @escaping () -> ()) {
        call(syncMock, args: completion)
    }
}
