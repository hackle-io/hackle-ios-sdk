//
//  MockUserTargetFetcher.swift
//  Hackle
//

@testable import Hackle
import MockingKit

class MockUserTargetFetcher: Mock, UserTargetEventsFetcher {

    init(result: Result<UserTargetEvents, Error>? = nil) {
        super.init()
        if let result {
            every(fetchMock).answers { _ in try result.get() }
        }
    }

    lazy var fetchMock = MockFunction.throwable(self, fetchStub)

    private func fetchStub(user: User) throws -> UserTargetEvents {
        UserTargetEvents.empty()
    }

    func fetch(user: User) async throws -> UserTargetEvents {
        try call(fetchMock, args: user)
    }
}
