import Foundation


class RemoteConfigEventDedupDeterminer: CachedUserEventDedupDeterminer {

    typealias Event = UserEvents.RemoteConfig

    private let dedupCache: UserEventDedupCache

    init(dedupInterval: TimeInterval) {
        dedupCache = UserEventDedupCache(dedupInterval: dedupInterval, clock: SystemClock.shared)
    }

    func cache() -> UserEventDedupCache {
        dedupCache
    }

    func cacheKey(event: Event) -> String {
        key(remoteConfigEvent: event)
    }

    private func key(remoteConfigEvent: UserEvents.RemoteConfig) -> String {
        [
            "\(remoteConfigEvent.parameter.id)",
            "\(remoteConfigEvent.valueId ?? 0)",
            remoteConfigEvent.decisionReason
        ].joined(separator: "-")
    }
}