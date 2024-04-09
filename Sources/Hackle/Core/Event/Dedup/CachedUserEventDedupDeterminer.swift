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
    private let dedupInterval: TimeInterval
    private let clock: Clock

    private var cache: [String: TimeInterval] = [String: TimeInterval]()
    private var currentUser: HackleUser? = nil

    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.UserEventDedupCache.Lock")

    init(dedupInterval: TimeInterval, clock: Clock) {
        self.dedupInterval = dedupInterval
        self.clock = clock
    }

    func compute(cacheKey: String, user: HackleUser) -> Bool {
        if dedupInterval == HackleConfig.NO_DEDUP {
            return false
        }

        return lock.write {
            if user.identifiers != currentUser?.identifiers {
                currentUser = user
                cache.removeAll()
            }

            let now = clock.now().timeIntervalSince1970

            if let firstTime = cache[cacheKey], now - firstTime <= dedupInterval {
                return true
            }

            cache[cacheKey] = now
            return false
        }
    }
}
