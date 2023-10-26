import Foundation
import Mockery
@testable import Hackle


class MockUserListener: Mock, UserListener {
    lazy var onUserUpdatedMock = MockFunction(self, onUserUpdated)

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        call(onUserUpdatedMock, args: (oldUser, newUser, timestamp))
    }
}
