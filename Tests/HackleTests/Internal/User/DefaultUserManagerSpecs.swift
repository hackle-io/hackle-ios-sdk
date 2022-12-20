import Foundation
import Quick
import Nimble
import Mockery
@testable import Hackle

class DefaultUserManagerSpecs: QuickSpec {
    override func spec() {
        it("updateUser") {
            func updateUser(
                _ u1: (String?, String?),
                _ u2: (String?, String?),
                _ isSame: Bool
            ) {
                let listener = UserListenerStub()
                let sut = DefaultUserManager()
                sut.addListener(listener: listener)

                let user1 = HackleUser.of(user: Hackle.user(userId: u1.0, deviceId: u1.1), hackleProperties: [:])
                let user2 = HackleUser.of(user: Hackle.user(userId: u2.0, deviceId: u2.1), hackleProperties: [:])


                sut.updateUser(user: user1)
                sut.updateUser(user: user2)

                if isSame {
                    expect(listener.invocations.count) == 0
                } else {
                    expect(listener.invocations.count) == 1
                }

            }

            updateUser((nil, nil), (nil, nil), true)
            updateUser((nil, nil), (nil, "a"), false)
            updateUser((nil, nil), (nil, "b"), false)
            updateUser((nil, nil), ("a", nil), true)
            updateUser((nil, nil), ("a", "a"), false)
            updateUser((nil, nil), ("a", "b"), false)
            updateUser((nil, nil), ("b", nil), true)
            updateUser((nil, nil), ("b", "a"), false)
            updateUser((nil, nil), ("b", "b"), false)

            updateUser((nil, "a"), (nil, nil), false)
            updateUser((nil, "a"), (nil, "a"), true)
            updateUser((nil, "a"), (nil, "b"), false)
            updateUser((nil, "a"), ("a", nil), false)
            updateUser((nil, "a"), ("a", "a"), true)
            updateUser((nil, "a"), ("a", "b"), false)
            updateUser((nil, "a"), ("b", nil), false)
            updateUser((nil, "a"), ("b", "a"), true)
            updateUser((nil, "a"), ("b", "b"), false)

            updateUser((nil, "b"), (nil, nil), false)
            updateUser((nil, "b"), (nil, "a"), false)
            updateUser((nil, "b"), (nil, "b"), true)
            updateUser((nil, "b"), ("a", nil), false)
            updateUser((nil, "b"), ("a", "a"), false)
            updateUser((nil, "b"), ("a", "b"), true)
            updateUser((nil, "b"), ("b", nil), false)
            updateUser((nil, "b"), ("b", "a"), false)
            updateUser((nil, "b"), ("b", "b"), true)


            updateUser(("a", nil), (nil, nil), true)
            updateUser(("a", nil), (nil, "a"), false)
            updateUser(("a", nil), (nil, "b"), false)
            updateUser(("a", nil), ("a", nil), true)
            updateUser(("a", nil), ("a", "a"), true)
            updateUser(("a", nil), ("a", "b"), true)
            updateUser(("a", nil), ("b", nil), false)
            updateUser(("a", nil), ("b", "a"), false)
            updateUser(("a", nil), ("b", "b"), false)

            updateUser(("a", "a"), (nil, nil), false)
            updateUser(("a", "a"), (nil, "a"), true)
            updateUser(("a", "a"), (nil, "b"), false)
            updateUser(("a", "a"), ("a", nil), true)
            updateUser(("a", "a"), ("a", "a"), true)
            updateUser(("a", "a"), ("a", "b"), true)
            updateUser(("a", "a"), ("b", nil), false)
            updateUser(("a", "a"), ("b", "a"), false)
            updateUser(("a", "a"), ("b", "b"), false)

            updateUser(("a", "b"), (nil, nil), false)
            updateUser(("a", "b"), (nil, "a"), false)
            updateUser(("a", "b"), (nil, "b"), true)
            updateUser(("a", "b"), ("a", nil), true)
            updateUser(("a", "b"), ("a", "a"), true)
            updateUser(("a", "b"), ("a", "b"), true)
            updateUser(("a", "b"), ("b", nil), false)
            updateUser(("a", "b"), ("b", "a"), false)
            updateUser(("a", "b"), ("b", "b"), false)


            updateUser(("b", nil), (nil, nil), true)
            updateUser(("b", nil), (nil, "a"), false)
            updateUser(("b", nil), (nil, "b"), false)
            updateUser(("b", nil), ("a", nil), false)
            updateUser(("b", nil), ("a", "a"), false)
            updateUser(("b", nil), ("a", "b"), false)
            updateUser(("b", nil), ("b", nil), true)
            updateUser(("b", nil), ("b", "a"), true)
            updateUser(("b", nil), ("b", "b"), true)

            updateUser(("b", "a"), (nil, nil), false)
            updateUser(("b", "a"), (nil, "a"), true)
            updateUser(("b", "a"), (nil, "b"), false)
            updateUser(("b", "a"), ("a", nil), false)
            updateUser(("b", "a"), ("a", "a"), false)
            updateUser(("b", "a"), ("a", "b"), false)
            updateUser(("b", "a"), ("b", nil), true)
            updateUser(("b", "a"), ("b", "a"), true)
            updateUser(("b", "a"), ("b", "b"), true)

            updateUser(("b", "b"), (nil, nil), false)
            updateUser(("b", "b"), (nil, "a"), false)
            updateUser(("b", "b"), (nil, "b"), true)
            updateUser(("b", "b"), ("a", nil), false)
            updateUser(("b", "b"), ("a", "a"), false)
            updateUser(("b", "b"), ("a", "b"), false)
            updateUser(("b", "b"), ("b", nil), true)
            updateUser(("b", "b"), ("b", "a"), true)
            updateUser(("b", "b"), ("b", "b"), true)
        }
    }


}


fileprivate class UserListenerStub: UserListener {

    var invocations = [(HackleUser, Date)]()

    func onUserUpdated(user: HackleUser, timestamp: Date) {
        invocations.append((user, timestamp))
    }
}