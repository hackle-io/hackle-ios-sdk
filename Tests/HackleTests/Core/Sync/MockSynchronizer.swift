//
//  MockSynchronizer.swift
//  HackleTests
//
//  Created by yong on 2023/10/02.
//

import Foundation
import MockingKit
@testable import Hackle

class MockSynchronizer: Mock, Synchronizer {
    override init() {
        super.init()
        every(syncMock).answers { completion in
            completion(.success(()))
        }
    }

    lazy var syncMock = MockFunction(self, sync)

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        call(syncMock, args: completion)
    }
}
