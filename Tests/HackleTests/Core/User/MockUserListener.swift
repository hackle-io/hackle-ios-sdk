import Foundation
import MockingKit
@testable import Hackle


class MockUserListener: Mock, UserListener {
    lazy var onUserUpdatedMock = MockFunction(self, onUserUpdated)

    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        call(onUserUpdatedMock, args: (oldUser, newUser, timestamp))
    }

    lazy var onPropertyOperationsMock = MockFunction(self, onPropertyOperations)

    func onPropertyOperations(user: User, operations: PropertyOperations, timestamp: Date) {
        call(onPropertyOperationsMock, args: (user, operations, timestamp))
    }
}
