import Foundation

class NotificationManager: NotificationDataReceiver {
    private static let DEFAULT_FLUSH_BATCH_SIZE = 5
    
    let core: HackleCore
    let dispatchQueue: DispatchQueue
    let workspaceFetcher: WorkspaceFetcher
    let userManager: UserManager
    let repository: NotificationRepository
    
    private let flusing: AtomicReference<Bool> = AtomicReference(value: false)
    
    init(
        core: HackleCore,
        dispatchQueue: DispatchQueue,
        workspaceFetcher: WorkspaceFetcher,
        userManager: UserManager,
        repository: NotificationRepository
    ) {
        self.core = core
        self.workspaceFetcher = workspaceFetcher
        self.userManager = userManager
        self.repository = repository
        self.dispatchQueue = dispatchQueue
    }
    
    func flush(batchSize: Int = DEFAULT_FLUSH_BATCH_SIZE) {
        if (flusing.getAndSet(newValue: true)) {
            return
        }
        
        defer {
            flusing.set(newValue: false)
        }
        
        guard let workspace = workspaceFetcher.fetch() else {
            Log.debug("Workspace data is empty.")
            return
        }
        
        let totalCount = repository.count(
            workspaceId: workspace.id,
            environmentId: workspace.environmentId
        )
        let loop = Int(ceil(Double(totalCount) / Double(batchSize)))
        Log.debug("Total notification data: \(totalCount)")
        
        for _ in 0...loop {
            let notifications = repository.getNotifications(
                workspaceId: workspace.id,
                environmentId: workspace.environmentId,
                limit: batchSize
            )
            
            if (notifications.isEmpty) {
                break
            }
            
            for notification in notifications {
                track(
                    event: notification.toTrackEvent(),
                    timestamp: notification.clickTimestamp
                )
                Log.debug("Notification data[\(notification.notificationId)] successfully processed.")
            }
            
            repository.delete(entities: notifications)
            Log.debug("Flushed notification data: \(notifications.count) items")
        }
        
        Log.debug("Finished notification data flush task.")
    }
    
    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {
        let workspace = workspaceFetcher.fetch()
        if let workspace = workspace,
               workspace.id == data.workspaceId,
               workspace.environmentId == data.environmentId {
            track(event: data.toTrackEvent(), timestamp: timestamp)
        } else {
            if workspace == nil {
                Log.debug("Workspace data is empty.")
            } else {
                Log.debug(
                    "Current environment(\(String(describing: workspace?.id)):\(String(describing: workspace?.environmentId))) is not same as notification environment(\(data.workspaceId):\(data.environmentId))."
                )
            }
            
            saveInLocal(data: data, timestamp: timestamp)
        }
    }
    
    private func saveInLocal(data: NotificationData, timestamp: Date) {
        DispatchQueue.main.async {
            let entity = data.toEntity(timestamp: timestamp)
            self.repository.save(entity: entity)
        }
    }
    
    private func track(event: Event, timestamp: Date) {
        let currentUser = userManager.currentUser
        let hackleUser = userManager.toHackleUser(user: currentUser)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
        Log.debug("\(event.key) event queued.")
    }
}
