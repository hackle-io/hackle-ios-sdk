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

        every(setUserMock).answers { user in
            self.currentUser = user
            return self.currentUser
        }
        every(setUserIdMock).answers { userId in
            self.currentUser = currentUser.toBuilder().userId(userId).build()
            return self.currentUser
        }

        every(setDeviceIdMock).answers { deviceId in
            self.currentUser = currentUser.toBuilder().deviceId(deviceId).build()
            return self.currentUser
        }

        every(updatePropertiesMock).answers { operations in
            self.currentUser = currentUser.toBuilder().properties(operations.operate(base: [:])).build()
            return self.currentUser
        }

        every(resetUserMock).answers {
            self.currentUser = User.builder().build()
            return self.currentUser
        }

        every(resolveMock).answers { user in
            HackleUser.of(user: user ?? self.currentUser, hackleProperties: [:])
        }
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