//
//  ExposureEventDedupDeterminer.swift
//  Hackle
//
//  Created by yong on 2022/08/11.
//

import Foundation

protocol ExposureEventDedupDeterminer {
    func isDedupTarget(event: UserEvent) -> Bool
}

class DefaultExposureEventDedupDeterminer: ExposureEventDedupDeterminer {

    private let dedupInterval: TimeInterval
    private let lock: ReadWriteLock = ReadWriteLock(label: "io.hackle.DefaultExposureEventDedupDeterminer.Lock")

    private var currentUser: HackleUser? = nil
    private var cache: [String: TimeInterval] = [String: TimeInterval]()

    init(dedupInterval: TimeInterval) {
        self.dedupInterval = dedupInterval
    }

    func isDedupTarget(event: UserEvent) -> Bool {

        if dedupInterval == HackleConfig.NO_DEDUP {
            return false
        }

        guard let exposureEvent = event as? UserEvents.Exposure else {
            return false
        }

        return lock.write {

            if exposureEvent.user.identifiers != currentUser?.identifiers {
                currentUser = event.user
                cache.removeAll()
            }

            let key = key(exposureEvent: exposureEvent)
            let now = Date().timeIntervalSince1970

            if let firstExposureTime = cache[key], firstExposureTime >= now - dedupInterval {
                return true
            }

            cache[key] = now
            return false
        }
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
