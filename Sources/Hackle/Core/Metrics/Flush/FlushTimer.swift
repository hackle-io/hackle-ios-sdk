//
//  FlushTimer.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class FlushTimer: FlushMetric, Timer {

    let id: MetricId
    private let current: AtomicReference<Timer>

    init(id: MetricId) {
        self.id = id
        current = AtomicReference(value: CumulativeTimer(id: id))
    }

    func flush() -> Metric {
        current.getAndSet(newValue: CumulativeTimer(id: id))
    }

    func count() -> Int64 {
        current.get().count()
    }

    func totalTime(unit: TimeUnit) -> Double {
        current.get().totalTime(unit: unit)
    }

    func max(unit: TimeUnit) -> Double {
        current.get().max(unit: unit)
    }

    func record(amount: Double, unit: TimeUnit) {
        current.get().record(amount: amount, unit: unit)
    }
}
