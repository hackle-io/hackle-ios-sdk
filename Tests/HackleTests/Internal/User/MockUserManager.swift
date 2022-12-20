import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class MockUserManager: Mock, UserManager {

    lazy var updateUserMock = MockFunction(self, updateUser)

    func updateUser(user: HackleUser) {
        call(updateUserMock, args: user)
    }
}