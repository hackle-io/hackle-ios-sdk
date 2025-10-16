import Foundation
import Quick
import Nimble
import MockingKit
@testable import Hackle

class MockUserManager: Mock, UserManager {

    var currentUser: User

    init(currentUser: User = HackleUserBuilder().build()) {
        self.currentUser = currentUser
        super.init()

        every(setUserMock).answers { user in
            let previous = self.currentUser
            self.currentUser = user
            return Updated(previous: previous, current: user)
        }
        every(setUserIdMock).answers { userId in
            let user = self.currentUser.toBuilder().userId(userId).build()
            let previous = self.currentUser
            self.currentUser = user
            return Updated(previous: previous, current: user)
        }

        every(setDeviceIdMock).answers { deviceId in
            let user = self.currentUser.toBuilder().deviceId(deviceId).build()
            let previous = self.currentUser
            self.currentUser = user
            return Updated(previous: previous, current: user)
        }

        every(updatePropertiesMock).answers { operations in
            let user = self.currentUser.toBuilder().properties(operations.operate(base: [:])).build()
            let previous = self.currentUser
            self.currentUser = user
            return Updated(previous: previous, current: user)
        }

        every(resetUserMock).answers {
            let user = User.builder().build()
            let previous = self.currentUser
            self.currentUser = user
            return Updated(previous: previous, current: user)
        }

        every(resolveMock).answers { user, hackleAppContext in
            HackleUser.of(user: user ?? self.currentUser, hackleProperties: [:])
                .toBuilder()
                .hackleProperties(hackleAppContext.browserProperties)
                .build()
        }

        every(syncIfNeededMock).answers { updated, completion in
            completion()
        }
    }

    lazy var initializeMock = MockFunction(self, initialize)

    func initialize(user: User?) {
        call(initializeMock, args: user)
    }

    lazy var resolveMock = MockFunction(self, resolve)
    var lastHackleAppContext: HackleAppContext?

    func resolve(user: User?, hackleAppContext: HackleAppContext) -> HackleUser {
        lastHackleAppContext = hackleAppContext
        return call(resolveMock, args: (user, hackleAppContext))
    }

    lazy var toHackleUserMock = MockFunction(self, toHackleUser)

    func toHackleUser(user: User) -> HackleUser {
        call(toHackleUserMock, args: user)
    }

    lazy var setUserMock = MockFunction(self, setUser)

    func setUser(user: User) -> Updated<User> {
        call(setUserMock, args: user)
    }

    lazy var setUserIdMock = MockFunction(self, setUserId)

    func setUserId(userId: String?) -> Updated<User> {
        call(setUserIdMock, args: userId)
    }

    lazy var setDeviceIdMock = MockFunction(self, setDeviceId)

    func setDeviceId(deviceId: String) -> Updated<User> {
        call(setDeviceIdMock, args: deviceId)
    }

    lazy var updatePropertiesMock = MockFunction(self, updateProperties)

    func updateProperties(operations: PropertyOperations) -> Updated<User> {
        call(updatePropertiesMock, args: operations)
    }

    lazy var resetUserMock = MockFunction(self, resetUser)

    func resetUser() -> Updated<User> {
        call(resetUserMock, args: ())
    }

    lazy var syncMock = MockFunction(self, sync)

    func sync(completion: @escaping (Result<(), Error>) -> ()) {
        call(syncMock, args: completion)
    }

    lazy var syncIfNeededMock = MockFunction(self, syncIfNeeded)

    func syncIfNeeded(updated: Updated<User>, completion: @escaping () -> ()) {
        call(syncIfNeededMock, args: (updated, completion))
    }
}
