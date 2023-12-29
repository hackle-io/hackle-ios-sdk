import Foundation

protocol NotificationDataReceiver {
    func onNotificationDataReceived(data: NotificationData, timestamp: Date)
}

class DefaultNotificationDataReceiver: NotificationDataReceiver {
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
            Log.debug("Saved notification data: \(String(describing: data.pushMessageId))[\(timestamp)]")
        }
    }
}
