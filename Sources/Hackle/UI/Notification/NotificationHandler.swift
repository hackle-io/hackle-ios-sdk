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
    
    /// 핵클 푸시를 처리합니다.
    /// - Parameters:
    ///   - data: notification data
    ///   - timestamp: push click timestamp
    ///   - customAction: true이면 개발사에서 직접 알림 액션 처리하고 false이면 sdk default
    func handleNotificationData(data: NotificationData, timestamp: Date = Date(), customAction: Bool = false) {
        receiver.onNotificationDataReceived(data: data, timestamp: timestamp)
        if !customAction {
            trampoline(data: data)
        }
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
                UIUtils.application?.open(url, options: [:]) { success in
                    Log.debug("Redirected to: \(link) [success=\(success)]")
                }
            } else {
                Log.info("Landing url is empty.")
            }
        }
    }
}
