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
    ///   - processHackleAction: false 이면 trampoline을 실행하지 않습니다.
    func handleNotificationData(data: NotificationData, timestamp: Date = Date(), processHackleAction: Bool) {
        receiver.onNotificationDataReceived(data: data, timestamp: timestamp)
        if processHackleAction {
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
