import Foundation
@testable import Hackle

class MockNotificationManager: NotificationManager {

    var onFlush: (() -> Void)? = nil

    func flush() {
        onFlush?()
    }

    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {

    }
}
