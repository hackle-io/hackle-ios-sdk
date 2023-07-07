import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockUserValueResolver: Mock, UserValueResolver {

    lazy var resolveOrNilMock = MockFunction(self, resolveOrNil)

    func resolveOrNil(user: HackleUser, key: Target.Key) throws -> Any? {
        call(resolveOrNilMock, args: (user, key))
    }
}