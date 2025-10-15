import Foundation
import UIKit

class ExposureEventDedupDeterminer: CachedUserEventDedupDeterminer {
    typealias Event = UserEvents.Exposure
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

extension ExposureEventDedupDeterminer: ApplicationLifecycleListener {
    func onForeground(_ topViewController: UIViewController?, timestamp: Date, isFromBackground: Bool) {
        // nothing to do
    }
    
    func onBackground(_ topViewController: UIViewController?, timestamp: Date) {
        Log.debug("ExposureEventDedupDeterminer.onBackground")
        self.dedupCache.saveToRepository()
    }
}
