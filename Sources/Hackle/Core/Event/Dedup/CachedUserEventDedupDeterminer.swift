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
    private let repositoryKeyDedupCache = "DEDUP_CACHE"
    private let repositoryKeyCurrentUser = "CURRENT_USE_PROPERTIES"
    private let cacheSizeLimit = 4 * 1024 * 1024 // UserDefaults storage limit is 4MB.
    
    private let dedupInterval: TimeInterval
    private let clock: Clock
    private var currentUserIdentifiers: [String: String]?
    private let repository: UserDefaultsKeyValueRepository
    
    private var cache = [String: TimeInterval]()
    private let lock = ReadWriteLock(label: "io.hackle.UserEventDedupCache.Lock")
    
    init(repository: UserDefaultsKeyValueRepository, dedupInterval: TimeInterval, clock: Clock) {
        self.repository = repository
        self.dedupInterval = dedupInterval
        self.clock = clock
        
        self.loadFromRepository()
    }

    func compute(cacheKey: String, user: HackleUser) -> Bool {
        if self.dedupInterval == HackleConfig.NO_DEDUP {
            return false
        }
        
        return lock.write {
            if user.identifiers != self.currentUserIdentifiers {
                self.cache.removeAll()
                self.currentUserIdentifiers = user.identifiers
            }
            
            let now = self.clock.now().timeIntervalSince1970
            if let firstTime = self.cache[cacheKey], now - firstTime <= self.dedupInterval {
                return true
                
            }
            self.cache[cacheKey] = now
            return false
        }
    }
}

extension UserEventDedupCache {
    func saveToRepository() {
        self.lock.write {
            self.saveCurrentUserToRepository()
            self.saveCacheToRepository()
        }
    }
    
    func loadFromRepository() {
        self.lock.write {
            self.loadCurrentUserFromRepository()
            self.loadCacheFromRepository()
        }
    }
    
    private func saveCurrentUserToRepository() {
        if let identifiers = self.currentUserIdentifiers?.toJson() {
            self.repository.putString(key: self.repositoryKeyCurrentUser, value: identifiers)
        } else {
            self.repository.remove(key: self.repositoryKeyCurrentUser)
        }
    }
    
    private func loadCurrentUserFromRepository() {
        if let identifiers = self.repository.getString(key: self.repositoryKeyCurrentUser) {
            self.currentUserIdentifiers = identifiers.jsonObject()?.compactMapValues { $0 as? String}
        }
        self.currentUserIdentifiers = nil
    }
    
    private func saveCacheToRepository() {
        self.updateCacheForIntervalExpiry()
        
        if self.cache.dataSizeInBytes() > self.cacheSizeLimit {
            Log.error("Fail to save event cache. The storage capacity for checking duplicate events has been exceeded.")
            return
        }
        
        if let cacheForSave = self.cache.toJson() {
            self.repository.putString(key: self.repositoryKeyDedupCache, value: cacheForSave)
        } else {
            self.repository.remove(key: self.repositoryKeyDedupCache)
        }
    }
    
    private func loadCacheFromRepository() {
        if let savedCacheStr = self.repository.getString(key: self.repositoryKeyDedupCache),
            let savedCache = savedCacheStr.jsonObject() {
            self.cache = savedCache.compactMapValues{ $0 as? Double }
            self.updateCacheForIntervalExpiry()
        }
    }
    
    private func updateCacheForIntervalExpiry() {
        let now = self.clock.now().timeIntervalSince1970
        for (key, value) in self.cache {
            if now - value > self.dedupInterval {
                self.cache.removeValue(forKey: key)
            }
        }
    }
}
