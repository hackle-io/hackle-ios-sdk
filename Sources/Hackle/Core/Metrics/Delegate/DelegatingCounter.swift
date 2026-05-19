//
//  DelegatingCounter.swift
//  Hackle
//
//  Created by yong on 2023/01/17.
//

import Foundation

class DelegatingCounter: DelegatingMetric, Counter, @unchecked Sendable {

    let id: MetricId

    private let noopCounter: Counter
    private let _counters: AtomicReference<[MetricRegistry: Counter]>

    private var counters: [Counter] {
        Array(_counters.get().values)
    }

    private var first: Counter {
        counters.first ?? noopCounter
    }

    init(id: MetricId) {
        self.id = id
        self.noopCounter = NoopCounter(id: id)
        self._counters = AtomicReference<[MetricRegistry: Counter]>(value: [:])
    }

    func add(registry: MetricRegistry) {
        let newCounter = registry.counter(id: id)
        let snapshot = _counters.get()
        if snapshot[registry] != nil { return }
        var updated = snapshot
        updated[registry] = newCounter
        _counters.set(newValue: updated)
    }

    func count() -> Int64 {
        first.count()
    }

    func increment(_ delta: Int64) {
        Metrics.queue.async { [weak self] in
            guard let self = self else { return }
            for c in self._counters.get().values {
                c.increment(delta)
            }
        }
    }
}
