import Foundation
import Mockery
@testable import Hackle


class MockPushTokenListener: Mock, PushTokenListener {

    lazy var onTokenRegisteredMock = MockFunction(self, onTokenRegistered)

    func onTokenRegistered(token: PushToken, timestamp: Date) {
        call(onTokenRegisteredMock, args: (token, timestamp))
    }
}
