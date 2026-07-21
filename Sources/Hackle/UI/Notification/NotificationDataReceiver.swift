import Foundation

protocol NotificationDataReceiver {
    func onNotificationDataReceived(data: NotificationData, timestamp: Date)
}

// 저장 프로퍼티가 모두 let(불변)이라 thread-safe.
final class DefaultNotificationDataReceiver: NotificationDataReceiver, @unchecked Sendable {
    let dispatchQueue: DispatchQueue
    let repository: NotificationRepository
    
    init(dispatchQueue: DispatchQueue, repository: NotificationRepository) {
        self.dispatchQueue = dispatchQueue
        self.repository = repository
    }
    
    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {
        saveInLocal(data: data, timestamp: timestamp)
    }
    
    private func saveInLocal(data: NotificationData, timestamp: Date) {
        dispatchQueue.async {
            self.repository.save(data: data, timestamp: timestamp)
            Log.info("Saved notification data in receiver: \(String(describing: data.pushMessageId))[\(timestamp)]")
        }
    }
}
