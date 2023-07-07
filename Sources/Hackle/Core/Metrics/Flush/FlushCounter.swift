//
//  FlushCounter.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation


class FlushCounter: FlushMetric, Counter {

    let id: MetricId
    private let current: AtomicReference<Counter>

    init(id: MetricId) {
        self.id = id
        current = AtomicReference(value: CumulativeCounter(id: id))
    }

    func flush() -> Metric {
        current.getAndSet(newValue: CumulativeCounter(id: id))
    }

    func count() -> Int64 {
        current.get().count()
    }

    func increment(_ delta: Int64) {
        current.get().increment(delta)
    }
}
