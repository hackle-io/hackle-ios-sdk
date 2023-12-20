import Foundation
import UserNotifications

class NotificationHandler {
    private static var receiver: NotificationDataReceiver =
        DefaultNotificationDataReceiver(
            dispatchQueue: DispatchQueue.main,
            repository: NotificationRepositoryImpl(
                sharedDatabase: DatabaseHelper.getSharedDatabase()
            )
        )
    
    static func setNotificationDataReceiver(receiver: NotificationDataReceiver) {
        self.receiver = receiver
    }
    
    static func handleNotificationData(data: NotificationData, timestamp: Date = Date()) {
        receiver.onNotificationDataReceived(data: data, timestamp: timestamp)
    }
}
