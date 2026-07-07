//
//  MockSynchronizer.swift
//  HackleTests
//

import Foundation
import MockingKit
@testable import Hackle

class MockSynchronizer: Mock, Synchronizer {
    override init() {
        super.init()
        every(syncMock).answers { _ in }
    }

    lazy var syncMock = MockFunction.throwable(self, syncStub)

    private func syncStub() throws {
    }

    func sync() async throws {
        try call(syncMock, args: ())
    }
}
