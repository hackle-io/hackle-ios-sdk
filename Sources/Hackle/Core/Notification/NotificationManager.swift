import Foundation

class NotificationManager: NotificationDataReceiver {
    let core: HackleCore
    let dispatchQueue: DispatchQueue
    let workspaceFetcher: WorkspaceFetcher
    let userManager: UserManager
    let repository: NotificationRepository
    
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
    
    func onNotificationDataReceived(data: NotificationData, timestamp: Date) {
        let workspace = workspaceFetcher.fetch()
        if let workspace = workspace,
               workspace.id == data.workspaceId,
               workspace.environmentId == data.environmentId {
            track(data: data, timestamp: timestamp)
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
    
    private func track(data: NotificationData, timestamp: Date) {
        let currentUser = userManager.currentUser
        let hackleUser = userManager.toHackleUser(user: currentUser)
        let event = data.toTrackEvent()
        core.track(event: event, user: hackleUser, timestamp: timestamp)
        let pushMessageId = data.pushMessageId ?? -1
        Log.debug("\(event.key)(\(pushMessageId)) event queued.")
    }
}
