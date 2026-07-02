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

    lazy var syncMock = MockFunction<Void, Result<Void, Error>>(self) { _ in .success(()) }

    func sync() async throws {
        try call(syncMock, args: ())
    }
}
