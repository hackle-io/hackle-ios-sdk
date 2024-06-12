//
//  DelegatingTimer.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class DelegatingTimer: DelegatingMetric, Timer {

    let id: MetricId

    private let lock = ReadWriteLock(label: "io.hackle.DelegatingTimer.Lock")
    private let noopTimer: Timer
    private var _timers: [MetricRegistry: Timer]

    private var timers: [Timer] {
        let timers: [Timer] = Array(_timers.values)
        return timers
    }

    init(id: MetricId) {
        self.id = id
        noopTimer = NoopTimer(id: id)
        _timers = [:]
    }

    func add(registry: MetricRegistry) {
        let newTimer = registry.timer(id: id)
        lock.write {
            var newTimers = _timers
            newTimers[registry] = newTimer
            _timers = newTimers
        }
    }

    private func first() -> Timer {
        timers.first ?? noopTimer
    }

    func count() -> Int64 {
        first().count()
    }

    func totalTime(unit: TimeUnit) -> Double {
        first().totalTime(unit: unit)
    }

    func max(unit: TimeUnit) -> Double {
        first().max(unit: unit)
    }

    func record(amount: Double, unit: TimeUnit) {
        for metric in timers {
            metric.record(amount: amount, unit: unit)
        }
    }
}
