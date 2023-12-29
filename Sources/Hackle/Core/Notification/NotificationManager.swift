import Foundation

class NotificationManager: NotificationDataReceiver, UserListener {
    private static let KEY_APNS_DEVICE_TOKEN = "apns_device_token"
    private static let DEFAULT_FLUSH_BATCH_SIZE = 5
    
    private let core: HackleCore
    private let dispatchQueue: DispatchQueue
    private let workspaceFetcher: WorkspaceFetcher
    private let userManager: UserManager
    private let preferences: KeyValueRepository
    private let repository: NotificationRepository
    
    private let flusing: AtomicReference<Bool> = AtomicReference(value: false)
    
    private var _apnsToken: String? {
        get {
            return preferences.getString(key: NotificationManager.KEY_APNS_DEVICE_TOKEN)
        }
        set {
            if let value = newValue {
                preferences.putString(
                    key: NotificationManager.KEY_APNS_DEVICE_TOKEN,
                    value: value
                )
            } else {
                preferences.remove(key: NotificationManager.KEY_APNS_DEVICE_TOKEN)
            }
        }
    }
    var apnsToken: String? {
        get { return preferences.getString(key: NotificationManager.KEY_APNS_DEVICE_TOKEN) }
    }
    
    init(
        core: HackleCore,
        dispatchQueue: DispatchQueue,
        workspaceFetcher: WorkspaceFetcher,
        userManager: UserManager,
        preferences: KeyValueRepository,
        repository: NotificationRepository
    ) {
        self.core = core
        self.workspaceFetcher = workspaceFetcher
        self.userManager = userManager
        self.repository = repository
        self.preferences = preferences
        self.dispatchQueue = dispatchQueue
    }
    
    func setAPNSToken(deviceToken: Data, timestamp: Date = Date()) {
        let deviceTokenString = deviceToken
            .map { String(format: "%.2hhx", $0) }
            .joined()
        if _apnsToken == deviceTokenString {
            Log.debug("Provided same device token.")
            return
        }
        
        Log.debug("New device token provided.")
        
        _apnsToken = deviceTokenString
        notifyAPNSTokenChanged(user: userManager.currentUser, timestamp: timestamp)
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
    
    func onUserUpdated(oldUser: User, newUser: User, timestamp: Date) {
        notifyAPNSTokenChanged(user: newUser, timestamp: timestamp)
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
    
    private func notifyAPNSTokenChanged(user: User, timestamp: Date) {
        guard let deviceTokenString = _apnsToken else {
            Log.debug("APNS token is empty.")
            return
        }
        
        let event = RegisterPushTokenEvent(token: deviceTokenString).toTrackEvent()
        track(event: event, user: user, timestamp: timestamp)
    }
    
    private func saveInLocal(data: NotificationData, timestamp: Date) {
        DispatchQueue.main.async {
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
