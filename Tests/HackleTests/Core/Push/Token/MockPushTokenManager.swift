import Foundation
@testable import Hackle


class MockPushTokenManager: PushTokenManager {

    var token: PushToken? = nil

    func currentToken() -> PushToken? {
        token
    }
}
