import Foundation


class ExposureEventDedupDeterminer: CachedUserEventDedupDeterminer {

    typealias Event = UserEvents.Exposure

    private let dedupCache: UserEventDedupCache

    init(sdkKey: String, dedupInterval: TimeInterval, appStateManager: DefaultAppStateManager) {
        let repositorySuiteName = String(format: storageSuiteNameExposureEventDedup, sdkKey)
        dedupCache = UserEventDedupCache(repositorySuiteName: repositorySuiteName,
                                         dedupInterval: dedupInterval,
                                         clock: SystemClock.shared,
                                         appStateManager: appStateManager)
    }

    func cache() -> UserEventDedupCache {
        dedupCache
    }

    func cacheKey(event: Event) -> String {
        key(exposureEvent: event)
    }

    private func key(exposureEvent: UserEvents.Exposure) -> String {
        [
            "\(exposureEvent.experiment.id)",
            "\(exposureEvent.variationId ?? 0)",
            exposureEvent.variationKey,
            exposureEvent.decisionReason
        ].joined(separator: "-")
    }
}
