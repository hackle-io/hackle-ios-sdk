import Foundation

class RemoteConfigEventDedupDeterminer: CachedUserEventDedupDeterminer {
    typealias Event = UserEvents.RemoteConfig
    private let dedupCache: UserEventDedupCache

    init(sdkKey: String, dedupInterval: TimeInterval, appStateManager: DefaultAppStateManager) {
        let repositorySuiteName = String(format: storageSuiteNameRemoteConfigEventDedup, sdkKey)
        dedupCache = UserEventDedupCache(repositorySuiteName: repositorySuiteName,
                                         dedupInterval: dedupInterval,
                                         clock: SystemClock.shared,
                                         appStateManager: appStateManager)
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
