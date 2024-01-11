import Foundation

protocol NotificationManager: NotificationDataReceiver, UserListener {
    var registeredPushToken: String? { get }
    func setPushToken(deviceToken: Data, timestamp: Date)
    func flush()
}

class DefaultNotificationManager: NotificationManager {
    private static let KEY_APNS_TOKEN = "apns_token"
    private static let DEFAULT_FLUSH_BATCH_SIZE = 5
    
    private let core: HackleCore
    private let dispatchQueue: DispatchQueue
    private let workspaceFetcher: WorkspaceFetcher
    private let userManager: UserManager
    private let preferences: KeyValueRepository
    private let repository: NotificationRepository
    
    private let flushing: AtomicReference<Bool> = AtomicReference(value: false)
    
    private var _registeredPushToken: String? {
        get {
            return preferences.getString(key: DefaultNotificationManager.KEY_APNS_TOKEN)
        }
        set {
            if let value = newValue {
                preferences.putString(
                    key: DefaultNotificationManager.KEY_APNS_TOKEN,
                    value: value
                )
            } else {
                preferences.remove(key: DefaultNotificationManager.KEY_APNS_TOKEN)
            }
        }
    }
    var registeredPushToken: String? {
        get { return preferences.getString(key: DefaultNotificationManager.KEY_APNS_TOKEN) }
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
    
    func setPushToken(deviceToken: Data, timestamp: Date) {
        let deviceTokenString = deviceToken.hexString()
        if _registeredPushToken == deviceTokenString {
            Log.debug("Provided same push token.")
            return
        }
        
        _registeredPushToken = deviceTokenString
        notifyAPNSTokenChanged(user: userManager.currentUser, timestamp: timestamp)
    }
    
    func flush() {
        dispatchQueue.async{
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
        guard let deviceTokenString = _registeredPushToken else {
            Log.debug("Push token is empty.")
            return
        }
        
        let event = RegisterPushTokenEvent(token: deviceTokenString).toTrackEvent()
        track(event: event, user: user, timestamp: timestamp)
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
