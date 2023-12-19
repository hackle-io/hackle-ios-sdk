import Foundation

protocol NotificationDataReceiver {
    func onNotificationDataReceived(data: NotificationData, timestamp: Date)
}

class DefaultNotificationDataReceiver: NotificationDataReceiver {
    let repository: NotificationRepository
    
    init(repository: NotificationRepository) {
        self.repository = repository
    }
    
    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {
        saveInLocal(data: data, timestamp: timestamp)
    }
    
    private func saveInLocal(data: NotificationData, timestamp: Date) {
        DispatchQueue.main.async {
            let entity = data.toEntity(timestamp: timestamp)
            self.repository.save(entity: entity)
            
            print("Saved count \(self.repository.count())")
        }
    }
}
