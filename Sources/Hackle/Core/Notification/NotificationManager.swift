import Foundation

protocol NotificationManager: NotificationDataReceiver {
    func flush()
}

class DefaultNotificationManager: NotificationManager {
    private static let DEFAULT_FLUSH_BATCH_SIZE = 5

    private let core: HackleCore
    private let dispatchQueue: DispatchQueue
    private let workspaceManager: WorkspaceManager
    private let userManager: UserManager
    private let repository: NotificationRepository

    private let flushing: AtomicReference<Bool> = AtomicReference(value: false)

    init(
        core: HackleCore,
        dispatchQueue: DispatchQueue,
        workspaceManager: WorkspaceManager,
        userManager: UserManager,
        repository: NotificationRepository
    ) {
        self.core = core
        self.workspaceManager = workspaceManager
        self.userManager = userManager
        self.repository = repository
        self.dispatchQueue = dispatchQueue
    }

    func flush() {
        dispatchQueue.async {
            self.flushInternal()
        }
    }

    private func flushInternal(
        batchSize: Int = DefaultNotificationManager.DEFAULT_FLUSH_BATCH_SIZE
    ) {
        if (flushing.getAndSet(newValue: true)) {
            return
        }

        defer {
            flushing.set(newValue: false)
        }

        guard let metadata = workspaceManager.metadata() else {
            Log.info("Workspace data is empty when notification data is flushing.")
            return
        }

        let user = userManager.currentUser
        let totalCount = repository.count(
            workspaceId: metadata.id,
            environmentId: metadata.environmentId
        )
        if (totalCount <= 0) {
            Log.info("Notification data is empty.")
            return
        }

        let loop = Int(ceil(Double(totalCount) / Double(batchSize)))
        Log.info("Notification data: \(totalCount)")

        for _ in 0...loop {
            let notifications = repository.getEntities(
                workspaceId: metadata.id,
                environmentId: metadata.environmentId,
                limit: batchSize
            )

            if (notifications.isEmpty) {
                Log.debug("Notification data is empty in loop.")
                break
            }

            for notification in notifications {
                track(
                    event: notification.toTrackEvent(),
                    user: user,
                    timestamp: notification.timestamp
                )
                Log.debug("Notification data[\(notification.historyId)] successfully processed.")
            }

            repository.delete(entities: notifications)
            Log.info("Flushed notification data: \(notifications.count) items")
        }

        Log.info("Finished notification data flush task.")
    }

    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {
        let metadata = workspaceManager.metadata()
        if let metadata = metadata,
           metadata.id == data.workspaceId,
           metadata.environmentId == data.environmentId {
            track(event: data.toTrackEvent(), user: userManager.currentUser, timestamp: timestamp)
        } else {
            if metadata == nil {
                Log.debug("Workspace data is empty.")
            } else {
                Log.info(
                    "Current environment(\(String(describing: metadata?.id)):\(String(describing: metadata?.environmentId))) is not same as notification environment(\(data.workspaceId):\(data.environmentId))."
                )
            }

            saveInLocal(data: data, timestamp: timestamp)
        }
    }

    private func saveInLocal(data: NotificationData, timestamp: Date) {
        dispatchQueue.async {
            self.repository.save(data: data, timestamp: timestamp)
            Log.info("Saved notification data: \(String(describing: data.pushMessageId))[\(timestamp)]")
        }
    }

    private func track(event: Event, user: User, timestamp: Date) {
        let hackleUser = userManager.hackleUser(user: user)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
        Log.info("Push click event queued.")
    }
}
