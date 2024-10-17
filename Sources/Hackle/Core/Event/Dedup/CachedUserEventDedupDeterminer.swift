import Foundation


protocol CachedUserEventDedupDeterminer: UserEventDedupDeterminer {

    associatedtype Event: UserEvent

    func cache() -> UserEventDedupCache
    func cacheKey(event: Event) -> String
}

extension CachedUserEventDedupDeterminer {

    func support(event: UserEvent) -> Bool {
        event is Event
    }

    func isDedupTarget(event: UserEvent) -> Bool {
        guard let event = event as? Event else {
            return false
        }
        let cacheKey = cacheKey(event: event)
        return cache().compute(cacheKey: cacheKey, user: event.user)
    }
}

class UserEventDedupCache {
    private let repositoryKeyDedup: String = "DEDUP_"
    private let repositoryKeyCurrentUser: String = "CURRENT_USE_PROPERTIES"
    
    private let dedupInterval: TimeInterval
    private let clock: Clock
    
    private var currentUserIdentifiers: [String: String]? = nil
    private let repository: UserDefaultsKeyValueRepository
    
    private let repositoryUpdateInterval: TimeInterval = 60
    private var repositoryUpdateTime: TimeInterval = 0
    
    init(repositorySuiteName: String, dedupInterval: TimeInterval, clock: Clock, appStateManager: DefaultAppStateManager) {
        self.dedupInterval = dedupInterval
        self.clock = clock
        self.repository = UserDefaultsKeyValueRepository.of(suiteName: repositorySuiteName)
        self.currentUserIdentifiers = loadCurrentUserFromRepository()
        appStateManager.addListener(listener: self)
        
        // When the app restarts, the appStateManager cannot detect the state change. So, when initializing, the repository is updated once.
        self.updateRepository()
    }

    func compute(cacheKey: String, user: HackleUser) -> Bool {
        if dedupInterval == HackleConfig.NO_DEDUP {
            return false
        }
        
        if user.identifiers != currentUserIdentifiers {
            repository.clear()
            currentUserIdentifiers = user.identifiers
            storeCurrentUserToRepository()
        }
         
        let now = clock.now().timeIntervalSince1970
        let firstTime = repository.getDouble(key: repositoryKeyDedup + cacheKey)
        if firstTime > 0, now - firstTime <= dedupInterval {
            return true
        }
        
        repository.putDouble(key: repositoryKeyDedup + cacheKey, value: now)
        return false
    }
    
    func storeCurrentUserToRepository() {
        if let identifiers = self.currentUserIdentifiers?.toJson() {
            repository.putString(key: repositoryKeyCurrentUser, value: identifiers)
        } else {
            repository.remove(key: repositoryKeyCurrentUser)
        }
    }
    
    func loadCurrentUserFromRepository() -> [String: String]? {
        if let identifiers = repository.getString(key: repositoryKeyCurrentUser) {
            return identifiers.jsonObject()?.compactMapValues { $0 as? String}
        }
        return nil
    }
}

extension UserEventDedupCache: AppStateListener {
    func onState(state: AppState, timestamp: Date) {
        // Updates the storage when the state changes without distinguishing between foreground and background.
        updateRepository()
    }
    
    func updateRepository() {
        let now = clock.now().timeIntervalSince1970
        // If switching between background and foreground occurs frequently and less than 1 minute has passed since the last update, do not perform the update.
        if now - repositoryUpdateTime < repositoryUpdateInterval {
            return
        }
        
        repositoryUpdateTime = now
        for (key, value) in repository.getAll() {
            if let time: Double = value as? Double , now - time > dedupInterval {
                if key.hasPrefix(repositoryKeyDedup) {
                    repository.remove(key: key)
                }
            }
        }
    }
}
