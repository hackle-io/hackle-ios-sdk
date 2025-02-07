//
//  MockUserTargetFetcher.swift
//  Hackle
//
//  Created by sungwoo.yeo on 2/7/25.
//

@testable import Hackle
import Mockery

class MockUserTargetFetcher: Mock, UserTargetFetcher {

    init(result: Result<UserTarget, Error>? = nil) {
        super.init()
        if let result {
            every(fetchMock).answers { user, completion in
                completion(result)
            }
        }
    }

    lazy var fetchMock = MockFunction(self, fetch)

    func fetch(user: User, completion: @escaping (Result<UserTarget, Error>) -> ()) {
        call(fetchMock, args: (user, completion))
    }
}
