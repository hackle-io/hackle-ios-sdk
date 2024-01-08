import Foundation
import UserNotifications

class NotificationHandler {
    
    static let shared = NotificationHandler()
    
    private var receiver: NotificationDataReceiver =
        DefaultNotificationDataReceiver(
            dispatchQueue: DispatchQueue.main,
            repository: DefaultNotificationRepository(
                sharedDatabase: DatabaseHelper.getSharedDatabase()
            )
        )
    
    func setNotificationDataReceiver(receiver: NotificationDataReceiver) {
        self.receiver = receiver
    }
    
    func handleNotificationData(data: NotificationData, timestamp: Date = Date()) {
        receiver.onNotificationDataReceived(data: data, timestamp: timestamp)
        trampoline(data: data)
    }
}

extension NotificationHandler {
    private func trampoline(data: NotificationData) {
        switch (data.clickAction) {
        case .APP_OPEN:
            break;
        case .DEEP_LINK:
            if let link = data.link,
               let url = URL(string: link) {
                UIUtils.application.open(url, options: [:]) { success in
                    Log.debug("Redirected to: \(link) [success=\(success)]")
                }
            } else {
                Log.debug("Landing url is empty.")
            }
        }
    }
}
