import Foundation
import Mockery
@testable import Hackle

class MockPushEventTracker: Mock, PushEventTracker {
    lazy var trackPushTokenMock = MockFunction(self, trackPushToken)

    func trackPushToken(pushToken: PushToken, user: User, timestamp: Date) {
        call(trackPushTokenMock, args: (pushToken, user, timestamp))
    }
}
