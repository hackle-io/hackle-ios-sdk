import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockUserManager: Mock, UserManager {
    private(set) var currentUser: User

    init(currentUser: User = HackleUserBuilder().build()) {
        self.currentUser = currentUser
        super.init()
    }

    func initialize(user: User?) {
    }

    lazy var setUserMock = MockFunction(self, setUser)

    func setUser(user: User) -> User {
        call(setUserMock, args: user)
    }

    lazy var setUserIdMock = MockFunction(self, setUserId)

    func setUserId(userId: String?) -> User {
        call(setUserIdMock, args: userId)
    }

    lazy var setDeviceIdMock = MockFunction(self, setDeviceId)

    func setDeviceId(deviceId: String) -> User {
        call(setDeviceIdMock, args: deviceId)
    }

    lazy var updatePropertiesMock = MockFunction(self, updateProperties)

    func updateProperties(operations: PropertyOperations) -> User {
        call(updatePropertiesMock, args: operations)
    }

    lazy var resetUserMock = MockFunction(self, resetUser)

    func resetUser() -> User {
        call(resetUserMock, args: ())
    }
}