import Foundation

protocol NotificationManager: NotificationDataReceiver {
    func flush()
}

class DefaultNotificationManager: NotificationManager {
    private static let DEFAULT_FLUSH_BATCH_SIZE = 5

    private let core: HackleCore
    private let dispatchQueue: DispatchQueue
    private let workspaceFetcher: WorkspaceFetcher
    private let userManager: UserManager
    private let repository: NotificationRepository

    private let flushing: AtomicReference<Bool> = AtomicReference(value: false)

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

        guard let workspace = workspaceFetcher.fetch() else {
            Log.debug("Workspace data is empty.")
            return
        }

        let user = userManager.currentUser
        let totalCount = repository.count(
            workspaceId: workspace.id,
            environmentId: workspace.environmentId
        )
        if (totalCount <= 0) {
            Log.debug("Notification data is empty.")
            return
        }

        let loop = Int(ceil(Double(totalCount) / Double(batchSize)))
        Log.debug("Notification data: \(totalCount)")

        for _ in 0...loop {
            let notifications = repository.getEntities(
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
                    user: user,
                    timestamp: notification.timestamp
                )
                Log.debug("Notification data[\(notification.historyId)] successfully processed.")
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
            track(event: data.toTrackEvent(), user: userManager.currentUser, timestamp: timestamp)
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
        dispatchQueue.async {
            self.repository.save(data: data, timestamp: timestamp)
            Log.debug("Saved notification data: \(String(describing: data.pushMessageId))[\(timestamp)]")
        }
    }

    private func track(event: Event, user: User, timestamp: Date) {
        let hackleUser = userManager.toHackleUser(user: user)
        core.track(event: event, user: hackleUser, timestamp: timestamp)
        Log.debug("\(event.key) event queued.")
    }
}
