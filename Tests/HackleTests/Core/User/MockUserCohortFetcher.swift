import Foundation
import MockingKit
@testable import Hackle


class MockUserCohortFetcher: Mock, UserCohortFetcher {

    init(result: Result<UserCohorts, Error>? = nil) {
        super.init()
        if let result {
            every(fetchMock).answers { _ in try result.get() }
        }
    }

    lazy var fetchMock = MockFunction.throwable(self, fetchStub)

    private func fetchStub(user: User) throws -> UserCohorts {
        UserCohorts.empty()
    }

    func fetch(user: User) async throws -> UserCohorts {
        try call(fetchMock, args: user)
    }
}
