import Foundation
import UserNotifications

class NotificationHandler {
    private static var receiver: NotificationDataReceiver =
        DefaultNotificationDataReceiver(
            repository: NotificationRepositoryImpl(
                sharedDatabase: DatabaseHelper.getSharedDatabase()
            )
        )
    
    static func handleNotificationData(data: NotificationData, timestamp: Date = Date()) {
        receiver.onNotificationDataReceived(data: data, timestamp: timestamp)
    }
}
