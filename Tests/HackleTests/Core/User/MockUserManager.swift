import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockUserManager: Mock, UserManager {

    var currentUser: User

    init(currentUser: User = HackleUserBuilder().build()) {
        self.currentUser = currentUser
        super.init()
    }

    lazy var initializeMock = MockFunction(self, initialize)

    func initialize(user: User?) {
        call(initializeMock, args: user)
    }

    lazy var resolveMock = MockFunction(self, resolve)

    func resolve(user: User?) -> HackleUser {
        call(resolveMock, args: user)
    }

    lazy var toHackleUserMock = MockFunction(self, toHackleUser)

    func toHackleUser(user: User) -> HackleUser {
        call(toHackleUserMock, args: user)
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

    lazy var syncMock = MockFunction(self, sync)

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        call(syncMock, args: completion)
    }
}