//
//  DelegatingTimer.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class DelegatingTimer: DelegatingMetric, Timer {

    let id: MetricId

    private let noopTimer: Timer
    private let _timers: AtomicReference<[MetricRegistry: Timer]>

    private var timers: [Timer] {
        Array(_timers.get().values)
    }

    init(id: MetricId) {
        self.id = id
        self.noopTimer = NoopTimer(id: id)
        self._timers = AtomicReference<[MetricRegistry: Timer]>(value: [:])
    }

    func add(registry: MetricRegistry) {
        let newTimer = registry.timer(id: id)
        let snapshot = _timers.get()
        if snapshot[registry] != nil { return }
        var updated = snapshot
        updated[registry] = newTimer
        _timers.set(newValue: updated)
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
        Metrics.queue.async { [weak self] in
            guard let self = self else { return }
            for t in self._timers.get().values {
                t.record(amount: amount, unit: unit)
            }
        }
    }
}
