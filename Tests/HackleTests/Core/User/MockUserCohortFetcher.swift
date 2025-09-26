import Foundation
import MockingKit
@testable import Hackle


class MockUserCohortFetcher: Mock, UserCohortFetcher {

    init(result: Result<UserCohorts, Error>? = nil) {
        super.init()
        if let result {
            every(fetchMock).answers { user, completion in
                completion(result)
            }
        }
    }

    lazy var fetchMock = MockFunction(self, fetch)

    func fetch(user: User, completion: @escaping (Result<UserCohorts, Error>) -> ()) {
        call(fetchMock, args: (user, completion))
    }
}
