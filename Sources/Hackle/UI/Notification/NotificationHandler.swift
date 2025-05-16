import Foundation
import UserNotifications

class NotificationHandler {
    static let shared = NotificationHandler(
        dispatchQueue: DispatchQueue(
            label: "io.hackle.NotificationHandler",
            qos: .utility
        )
    )

    private var receiver: NotificationDataReceiver

    init(dispatchQueue: DispatchQueue) {
        receiver = DefaultNotificationDataReceiver(
            dispatchQueue: dispatchQueue,
            repository: DefaultNotificationRepository(
                sharedDatabase: DatabaseHelper.getSharedDatabase()
            )
        )
    }

    func setNotificationDataReceiver(receiver: NotificationDataReceiver) {
        self.receiver = receiver
    }
    
    func trackPushClickEvent(notificationData: NotificationData, timestamp: Date = Date()) {
        Log.info("track push click event")
        receiver.onNotificationDataReceived(data: notificationData, timestamp: timestamp)
    }
    
    func handlePushClickAction(notificationData: NotificationData) {
        Log.info("handle push click action: \(notificationData.actionType.rawValue)")
        trampoline(data: notificationData)
    }
}

extension NotificationHandler {
    private func trampoline(data: NotificationData) {
        switch (data.clickAction) {
        case .appOpen:
            break;
        case .deepLink:
            if let link = data.link,
               let url = URL(string: link) {
                url.open()
            } else {
                Log.info("Landing url is empty.")
            }
        }
    }
}

extension URL {
    fileprivate func open() {
        guard let scheme = self.scheme else {
            return
        }
        
        if scheme == "http" || scheme == "https" {
            let userActivity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
            userActivity.webpageURL = self
            let success = UIUtils.application?.delegate?.application?(
                UIUtils.application!,
                continue: userActivity,
                restorationHandler: { _ in }
            )
            Log.debug("Redirected to: \(self.absoluteString) [success=\(success ?? false)]")

        } else {
            UIUtils.application?.open(self, options: [:]) { success in
                Log.debug("Redirected to: \(self.absoluteString) [success=\(success)]")
            }
        }
    }
}
