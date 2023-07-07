//
//  CumulativeTimer.swift
//  Hackle
//
//  Created by yong on 2023/01/16.
//

import Foundation

class CumulativeTimer: Timer {

    let id: MetricId

    private let _count = AtomicInt64(value: 0)
    private let _total = AtomicDouble(value: 0)
    private let _max = AtomicDouble(value: 0)

    init(id: MetricId) {
        self.id = id
    }

    func count() -> Int64 {
        _count.get()
    }

    func totalTime(unit: TimeUnit) -> Double {
        TimeUnit.nanosToUnit(nanos: _total.get(), unit: unit)
    }

    func max(unit: TimeUnit) -> Double {
        TimeUnit.nanosToUnit(nanos: _max.get(), unit: unit)
    }

    func record(amount: Double, unit: TimeUnit) {
        guard amount >= 0 else {
            return
        }
        let nanos = unit.convert(amount, to: .nanoseconds)
        let _ = _count.addAndGet(1)
        let _ = _total.addAndGet(nanos)
        let _ = _max.accumulateAndGet(nanos, Swift.max)
    }
}
