import Foundation
import MockingKit
@testable import Hackle

class MockInAppMessageResetProcessor: Mock, InAppMessageResetProcessor {
    lazy var processMock = MockFunction(self, process)

    func process(oldUser: User, newUser: User) {
        call(processMock, args: (oldUser, newUser))
    }
}
