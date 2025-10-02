import Foundation

class RemoteConfigEventDedupDeterminer: CachedUserEventDedupDeterminer {
    typealias Event = UserEvents.RemoteConfig
    private let dedupCache: UserEventDedupCache

    init(repository: UserDefaultsKeyValueRepository, dedupInterval: TimeInterval) {
        dedupCache = UserEventDedupCache(repository: repository,
                                         dedupInterval: dedupInterval,
                                         clock: SystemClock.shared)
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

extension RemoteConfigEventDedupDeterminer: AppStateListener {
    func onState(state: ApplicationState, timestamp: Date) {
        Log.debug("RemoteConfigEventDedupDeterminer.onState(state: \(state))")
        if state == .background {
            self.dedupCache.saveToRepository()
        }
    }
}
