//
//  MockSynchronizer.swift
//  HackleTests
//
//  Created by yong on 2023/10/02.
//

import Foundation
import Mockery
@testable import Hackle

class MockSynchronizer: Mock, CompositeSynchronizer {
    override init() {
        super.init()
        every(syncMock).answers { completion in
            completion(.success(()))
        }
        every(syncOnlyMock).answers { type, completion in
            completion(.success(()))
        }
    }

    lazy var syncMock = MockFunction(self, sync)

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        call(syncMock, args: completion)
    }

    lazy var syncOnlyMock = MockFunction(self, syncOnly)

    func syncOnly(type: SynchronizerType, completion: @escaping (Result<(), Error>) -> ()) {
        call(syncOnlyMock, args: (type, completion))
    }
}


